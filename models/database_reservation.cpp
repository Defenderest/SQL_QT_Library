#include "database.h"

#include <QDateTime>
#include <QSqlQuery>
#include <QVariant>
#include <QVector>

namespace {
constexpr int kReservationRefreshIntervalSeconds = 30;
constexpr int kDefaultReservationHoldMinutes = 15;
constexpr int kMaxReservationHoldMinutes = 60;

bool isActiveReservationStatus(const QString& status)
{
    return status.trimmed().compare(QStringLiteral("active"), Qt::CaseInsensitive) == 0;
}

int clampReservationHoldMinutes(int holdMinutes)
{
    if (holdMinutes <= 0) {
        return kDefaultReservationHoldMinutes;
    }
    return holdMinutes > kMaxReservationHoldMinutes ? kMaxReservationHoldMinutes : holdMinutes;
}
}

void DatabaseManager::ensureReservationStateFresh() const
{
    if (!m_isConnected || !m_db.isOpen()) {
        return;
    }

    const QDateTime now = QDateTime::currentDateTimeUtc();
    if (m_lastReservationCleanup.isValid() &&
        m_lastReservationCleanup.secsTo(now) < kReservationRefreshIntervalSeconds) {
        return;
    }

    DatabaseManager* self = const_cast<DatabaseManager*>(this);
    if (self->cleanupExpiredBookReservations()) {
        self->m_lastReservationCleanup = now;
    }
}

bool DatabaseManager::cleanupExpiredBookReservations()
{
    if (!m_isConnected || !m_db.isOpen()) {
        return false;
    }

    const QString expiredSql = getSqlQuery(QStringLiteral("GetExpiredActiveBookReservationsForUpdate"));
    const QString itemsSql = getSqlQuery(QStringLiteral("GetBookReservationItemsByReservationId"));
    const QString increaseStockSql = getSqlQuery(QStringLiteral("IncreaseBookStock"));
    const QString updateStatusSql = getSqlQuery(QStringLiteral("UpdateBookReservationStatusById"));
    if (expiredSql.isEmpty() || itemsSql.isEmpty() || increaseStockSql.isEmpty() || updateStatusSql.isEmpty()) {
        return false;
    }

    if (!m_db.transaction()) {
        qCritical() << "Failed to start transaction for reservation cleanup:" << m_db.lastError().text();
        return false;
    }

    bool success = true;
    QVector<int> expiredReservationIds;

    QSqlQuery expiredQuery(m_db);
    if (!expiredQuery.prepare(expiredSql) || !expiredQuery.exec()) {
        qCritical() << "Failed to load expired reservations:" << expiredQuery.lastError().text();
        success = false;
    } else {
        while (expiredQuery.next()) {
            expiredReservationIds.append(expiredQuery.value(0).toInt());
        }
    }

    if (success && !expiredReservationIds.isEmpty()) {
        QSqlQuery itemsQuery(m_db);
        QSqlQuery increaseStockQuery(m_db);
        QSqlQuery updateStatusQuery(m_db);

        if (!itemsQuery.prepare(itemsSql) ||
            !increaseStockQuery.prepare(increaseStockSql) ||
            !updateStatusQuery.prepare(updateStatusSql)) {
            qCritical() << "Failed to prepare reservation cleanup queries:"
                        << itemsQuery.lastError().text()
                        << increaseStockQuery.lastError().text()
                        << updateStatusQuery.lastError().text();
            success = false;
        }

        for (int reservationId : expiredReservationIds) {
            if (!success) {
                break;
            }

            itemsQuery.bindValue(QStringLiteral(":reservation_id"), reservationId);
            if (!itemsQuery.exec()) {
                qCritical() << "Failed to load reservation items for cleanup:" << itemsQuery.lastError().text();
                success = false;
                break;
            }

            while (itemsQuery.next()) {
                const int bookId = itemsQuery.value(QStringLiteral("book_id")).toInt();
                const int quantity = itemsQuery.value(QStringLiteral("quantity")).toInt();

                increaseStockQuery.bindValue(QStringLiteral(":book_id"), bookId);
                increaseStockQuery.bindValue(QStringLiteral(":quantity"), quantity);
                if (!increaseStockQuery.exec()) {
                    qCritical() << "Failed to restore stock for expired reservation:" << increaseStockQuery.lastError().text();
                    success = false;
                    break;
                }
            }

            if (!success) {
                break;
            }

            updateStatusQuery.bindValue(QStringLiteral(":reservation_id"), reservationId);
            updateStatusQuery.bindValue(QStringLiteral(":status"), QStringLiteral("expired"));
            if (!updateStatusQuery.exec()) {
                qCritical() << "Failed to mark reservation as expired:" << updateStatusQuery.lastError().text();
                success = false;
                break;
            }
        }
    }

    if (!success) {
        m_db.rollback();
        return false;
    }

    if (!m_db.commit()) {
        qCritical() << "Failed to commit reservation cleanup:" << m_db.lastError().text();
        m_db.rollback();
        return false;
    }

    if (!expiredReservationIds.isEmpty()) {
        qInfo() << "Expired reservations released:" << expiredReservationIds.size();
    }

    return true;
}

bool DatabaseManager::createBookReservation(int customerId,
                                            const QString& providerOrderId,
                                            const QMap<int, int>& items,
                                            int holdMinutes,
                                            QString* errorMessage)
{
    if (errorMessage) {
        errorMessage->clear();
    }

    if (!m_isConnected || !m_db.isOpen()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Немає підключення до бази даних");
        }
        return false;
    }

    if (customerId <= 0 || providerOrderId.trimmed().isEmpty() || items.isEmpty()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Неможливо створити бронь для порожнього замовлення");
        }
        return false;
    }

    ensureReservationStateFresh();

    const QString insertReservationSql = getSqlQuery(QStringLiteral("InsertBookReservation"));
    const QString insertReservationItemSql = getSqlQuery(QStringLiteral("InsertBookReservationItem"));
    const QString lockBookSql = getSqlQuery(QStringLiteral("GetBookPriceAndStockForUpdate"));
    const QString updateBookStockSql = getSqlQuery(QStringLiteral("UpdateBookStock"));
    if (insertReservationSql.isEmpty() || insertReservationItemSql.isEmpty() ||
        lockBookSql.isEmpty() || updateBookStockSql.isEmpty()) {
        return false;
    }

    if (!m_db.transaction()) {
        qCritical() << "Failed to start transaction for book reservation:" << m_db.lastError().text();
        if (errorMessage) {
            *errorMessage = QStringLiteral("Не вдалося розпочати бронювання книг");
        }
        return false;
    }

    bool success = true;
    QVariant insertedReservationId;

    QSqlQuery insertReservationQuery(m_db);
    if (!insertReservationQuery.prepare(insertReservationSql)) {
        qCritical() << "Failed to prepare reservation insert:" << insertReservationQuery.lastError().text();
        success = false;
    } else {
        const int effectiveHoldMinutes = clampReservationHoldMinutes(holdMinutes);
        insertReservationQuery.bindValue(QStringLiteral(":customer_id"), customerId);
        insertReservationQuery.bindValue(QStringLiteral(":provider_order_id"), providerOrderId.trimmed());
        insertReservationQuery.bindValue(QStringLiteral(":status"), QStringLiteral("active"));
        insertReservationQuery.bindValue(QStringLiteral(":expires_at"),
                                         QDateTime::currentDateTimeUtc().addSecs(effectiveHoldMinutes * 60));
        if (!executeInsertQuery(insertReservationQuery, QStringLiteral("InsertBookReservation"), insertedReservationId)) {
            success = false;
            if (errorMessage) {
                *errorMessage = QStringLiteral("Не вдалося створити бронь книг");
            }
        }
    }

    const int reservationId = insertedReservationId.toInt();
    if (success && reservationId <= 0) {
        success = false;
        if (errorMessage) {
            *errorMessage = QStringLiteral("Бронювання не повернуло коректний ідентифікатор");
        }
    }

    QSqlQuery lockBookQuery(m_db);
    QSqlQuery updateBookStockQuery(m_db);
    QSqlQuery insertReservationItemQuery(m_db);
    if (success && (!lockBookQuery.prepare(lockBookSql) ||
                    !updateBookStockQuery.prepare(updateBookStockSql) ||
                    !insertReservationItemQuery.prepare(insertReservationItemSql))) {
        qCritical() << "Failed to prepare reservation item queries:"
                    << lockBookQuery.lastError().text()
                    << updateBookStockQuery.lastError().text()
                    << insertReservationItemQuery.lastError().text();
        success = false;
    }

    for (auto it = items.constBegin(); success && it != items.constEnd(); ++it) {
        const int bookId = it.key();
        const int quantity = it.value();

        if (bookId <= 0 || quantity <= 0) {
            if (errorMessage) {
                *errorMessage = QStringLiteral("У кошику є некоректна позиція для бронювання");
            }
            success = false;
            break;
        }

        lockBookQuery.bindValue(QStringLiteral(":book_id"), bookId);
        if (!lockBookQuery.exec()) {
            qCritical() << "Failed to lock book for reservation:" << lockBookQuery.lastError().text();
            if (errorMessage) {
                *errorMessage = QStringLiteral("Не вдалося перевірити залишок книги перед оплатою");
            }
            success = false;
            break;
        }

        if (!lockBookQuery.next()) {
            if (errorMessage) {
                *errorMessage = QStringLiteral("Одну з книг уже видалено або вона недоступна");
            }
            success = false;
            break;
        }

        const int currentStock = lockBookQuery.value(1).toInt();
        if (quantity > currentStock) {
            if (errorMessage) {
                *errorMessage = QStringLiteral("Потрібної кількості більше немає на складі");
            }
            success = false;
            break;
        }

        updateBookStockQuery.bindValue(QStringLiteral(":book_id"), bookId);
        updateBookStockQuery.bindValue(QStringLiteral(":quantity"), quantity);
        if (!updateBookStockQuery.exec() || updateBookStockQuery.numRowsAffected() == 0) {
            qCritical() << "Failed to decrease stock for reservation:" << updateBookStockQuery.lastError().text();
            if (errorMessage) {
                *errorMessage = QStringLiteral("Не вдалося зафіксувати залишок книги на час оплати");
            }
            success = false;
            break;
        }

        insertReservationItemQuery.bindValue(QStringLiteral(":reservation_id"), reservationId);
        insertReservationItemQuery.bindValue(QStringLiteral(":book_id"), bookId);
        insertReservationItemQuery.bindValue(QStringLiteral(":quantity"), quantity);
        if (!insertReservationItemQuery.exec()) {
            qCritical() << "Failed to save reservation item:" << insertReservationItemQuery.lastError().text();
            if (errorMessage) {
                *errorMessage = QStringLiteral("Не вдалося зберегти склад бронювання");
            }
            success = false;
            break;
        }
    }

    if (!success) {
        m_db.rollback();
        return false;
    }

    if (!m_db.commit()) {
        qCritical() << "Failed to commit reservation transaction:" << m_db.lastError().text();
        m_db.rollback();
        if (errorMessage) {
            *errorMessage = QStringLiteral("Не вдалося завершити бронювання книг");
        }
        return false;
    }

    return true;
}

bool DatabaseManager::releaseBookReservationByProviderOrderId(const QString& providerOrderId,
                                                              const QString& status,
                                                              QString* errorMessage)
{
    if (errorMessage) {
        errorMessage->clear();
    }

    if (!m_isConnected || !m_db.isOpen() || providerOrderId.trimmed().isEmpty()) {
        return false;
    }

    const QString reservationSql = getSqlQuery(QStringLiteral("GetBookReservationByProviderOrderIdForUpdate"));
    const QString itemsSql = getSqlQuery(QStringLiteral("GetBookReservationItemsByReservationId"));
    const QString increaseStockSql = getSqlQuery(QStringLiteral("IncreaseBookStock"));
    const QString updateStatusSql = getSqlQuery(QStringLiteral("UpdateBookReservationStatusById"));
    if (reservationSql.isEmpty() || itemsSql.isEmpty() || increaseStockSql.isEmpty() || updateStatusSql.isEmpty()) {
        return false;
    }

    if (!m_db.transaction()) {
        qCritical() << "Failed to start transaction for reservation release:" << m_db.lastError().text();
        return false;
    }

    bool success = true;
    int reservationId = -1;
    QString currentStatus;

    QSqlQuery reservationQuery(m_db);
    if (!reservationQuery.prepare(reservationSql)) {
        qCritical() << "Failed to prepare reservation lookup for release:" << reservationQuery.lastError().text();
        success = false;
    } else {
        reservationQuery.bindValue(QStringLiteral(":provider_order_id"), providerOrderId.trimmed());
        if (!reservationQuery.exec()) {
            qCritical() << "Failed to load reservation for release:" << reservationQuery.lastError().text();
            success = false;
        } else if (reservationQuery.next()) {
            reservationId = reservationQuery.value(QStringLiteral("reservation_id")).toInt();
            currentStatus = reservationQuery.value(QStringLiteral("status")).toString();
        }
    }

    if (success && reservationId <= 0) {
        m_db.rollback();
        return true;
    }

    if (success && !isActiveReservationStatus(currentStatus)) {
        if (!m_db.commit()) {
            qCritical() << "Failed to commit no-op reservation release:" << m_db.lastError().text();
            m_db.rollback();
            return false;
        }
        return true;
    }

    QSqlQuery itemsQuery(m_db);
    QSqlQuery increaseStockQuery(m_db);
    QSqlQuery updateStatusQuery(m_db);
    if (success && (!itemsQuery.prepare(itemsSql) ||
                    !increaseStockQuery.prepare(increaseStockSql) ||
                    !updateStatusQuery.prepare(updateStatusSql))) {
        qCritical() << "Failed to prepare reservation release queries:"
                    << itemsQuery.lastError().text()
                    << increaseStockQuery.lastError().text()
                    << updateStatusQuery.lastError().text();
        success = false;
    }

    if (success) {
        itemsQuery.bindValue(QStringLiteral(":reservation_id"), reservationId);
        if (!itemsQuery.exec()) {
            qCritical() << "Failed to load reservation items for release:" << itemsQuery.lastError().text();
            success = false;
        }
    }

    while (success && itemsQuery.next()) {
        increaseStockQuery.bindValue(QStringLiteral(":book_id"), itemsQuery.value(QStringLiteral("book_id")).toInt());
        increaseStockQuery.bindValue(QStringLiteral(":quantity"), itemsQuery.value(QStringLiteral("quantity")).toInt());
        if (!increaseStockQuery.exec()) {
            qCritical() << "Failed to restore stock while releasing reservation:" << increaseStockQuery.lastError().text();
            success = false;
        }
    }

    if (success) {
        updateStatusQuery.bindValue(QStringLiteral(":reservation_id"), reservationId);
        updateStatusQuery.bindValue(QStringLiteral(":status"), status.trimmed().isEmpty() ? QStringLiteral("released") : status.trimmed());
        if (!updateStatusQuery.exec()) {
            qCritical() << "Failed to update reservation release status:" << updateStatusQuery.lastError().text();
            success = false;
        }
    }

    if (!success) {
        m_db.rollback();
        if (errorMessage) {
            *errorMessage = QStringLiteral("Не вдалося зняти бронь книг");
        }
        return false;
    }

    if (!m_db.commit()) {
        qCritical() << "Failed to commit reservation release:" << m_db.lastError().text();
        m_db.rollback();
        if (errorMessage) {
            *errorMessage = QStringLiteral("Не вдалося завершити зняття броні");
        }
        return false;
    }

    return true;
}

bool DatabaseManager::completeBookReservationByProviderOrderId(const QString& providerOrderId,
                                                               int orderId,
                                                               QString* errorMessage)
{
    if (errorMessage) {
        errorMessage->clear();
    }

    if (!m_isConnected || !m_db.isOpen() || providerOrderId.trimmed().isEmpty() || orderId <= 0) {
        return false;
    }

    const QString reservationSql = getSqlQuery(QStringLiteral("GetBookReservationByProviderOrderIdForUpdate"));
    const QString completeSql = getSqlQuery(QStringLiteral("CompleteBookReservationById"));
    if (reservationSql.isEmpty() || completeSql.isEmpty()) {
        return false;
    }

    if (!m_db.transaction()) {
        qCritical() << "Failed to start transaction for reservation completion:" << m_db.lastError().text();
        return false;
    }

    bool success = true;
    int reservationId = -1;
    QString currentStatus;
    int linkedOrderId = -1;

    QSqlQuery reservationQuery(m_db);
    if (!reservationQuery.prepare(reservationSql)) {
        qCritical() << "Failed to prepare reservation lookup for completion:" << reservationQuery.lastError().text();
        success = false;
    } else {
        reservationQuery.bindValue(QStringLiteral(":provider_order_id"), providerOrderId.trimmed());
        if (!reservationQuery.exec()) {
            qCritical() << "Failed to load reservation for completion:" << reservationQuery.lastError().text();
            success = false;
        } else if (reservationQuery.next()) {
            reservationId = reservationQuery.value(QStringLiteral("reservation_id")).toInt();
            currentStatus = reservationQuery.value(QStringLiteral("status")).toString();
            linkedOrderId = reservationQuery.value(QStringLiteral("order_id")).toInt();
        }
    }

    if (success && reservationId <= 0) {
        success = false;
        if (errorMessage) {
            *errorMessage = QStringLiteral("Бронювання для платежу не знайдено");
        }
    }

    if (success && currentStatus.trimmed().compare(QStringLiteral("completed"), Qt::CaseInsensitive) == 0) {
        const bool alreadyCompleted = linkedOrderId == orderId;
        if (m_db.commit()) {
            return alreadyCompleted;
        }
        qCritical() << "Failed to commit no-op reservation completion:" << m_db.lastError().text();
        m_db.rollback();
        return false;
    }

    if (success && !isActiveReservationStatus(currentStatus)) {
        success = false;
        if (errorMessage) {
            *errorMessage = QStringLiteral("Бронювання вже неактивне");
        }
    }

    if (success) {
        QSqlQuery completeQuery(m_db);
        if (!completeQuery.prepare(completeSql)) {
            qCritical() << "Failed to prepare reservation completion update:" << completeQuery.lastError().text();
            success = false;
        } else {
            completeQuery.bindValue(QStringLiteral(":reservation_id"), reservationId);
            completeQuery.bindValue(QStringLiteral(":status"), QStringLiteral("completed"));
            completeQuery.bindValue(QStringLiteral(":order_id"), orderId);
            if (!completeQuery.exec()) {
                qCritical() << "Failed to mark reservation as completed:" << completeQuery.lastError().text();
                success = false;
            }
        }
    }

    if (!success) {
        m_db.rollback();
        return false;
    }

    if (!m_db.commit()) {
        qCritical() << "Failed to commit reservation completion:" << m_db.lastError().text();
        m_db.rollback();
        return false;
    }

    return true;
}
