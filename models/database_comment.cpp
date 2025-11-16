#include "database.h"
#include <QDebug>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>
#include <QDateTime>

bool DatabaseManager::hasUserCommentedOnBook(int bookId, int customerId) const
{
    if (!m_isConnected || !m_db.isOpen() || bookId <= 0 || customerId <= 0) {
        qWarning() << "Неможливо перевірити коментар: немає з'єднання або невірний ID книги/користувача.";
        return false;
    }

    const QString sql = getSqlQuery("CheckUserCommentExists");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'CheckUserCommentExists' не знайдено.";
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'CheckUserCommentExists':" << query.lastError().text();
        return false;
    }
    query.bindValue(":bookId", bookId);
    query.bindValue(":customerId", customerId);

    qInfo() << "Виконання SQL 'CheckUserCommentExists' для користувача" << customerId << "на книзі" << bookId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'CheckUserCommentExists' для book ID '" << bookId << "' та customer ID '" << customerId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        return false;
    }

    if (query.next()) {
        int count = query.value(0).toInt();
        qInfo() << "Результат перевірки коментаря: count =" << count;
        return count > 0;
    }

    qWarning() << "Запит перевірки коментаря не повернув результату.";
    return false;
}


bool DatabaseManager::addComment(int bookId, int customerId, const QString &commentText, int rating)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо додати коментар: немає з'єднання з БД.";
        return false;
    }
    if (bookId <= 0 || customerId <= 0 || commentText.trimmed().isEmpty()) {
        qWarning() << "Неможливо додати коментар: невірний ID книги/користувача або порожній текст.";
        return false;
    }
    if (rating < 0 || rating > 5) {
        qWarning() << "Неможливо додати коментар: невірний рейтинг (" << rating << "). Допустимі значення: 0-5.";
        return false;
    }

    const QString sql = getSqlQuery("AddComment");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'AddComment' не знайдено.";
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'AddComment':" << query.lastError().text();
        return false;
    }
    query.bindValue(":book_id", bookId);
    query.bindValue(":customer_id", customerId);
    query.bindValue(":comment_text", commentText.trimmed());
    query.bindValue(":rating", (rating == 0) ? QVariant(QVariant::Int) : rating);

    qInfo() << "Виконання SQL 'AddComment' для book ID:" << bookId << "від customer ID:" << customerId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'AddComment' для book ID '" << bookId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return false;
    }

    qInfo() << "Коментар успішно додано для book ID:" << bookId;
    return true;
}

QList<CommentDisplayInfo> DatabaseManager::getBookComments(int bookId) const
{
    QList<CommentDisplayInfo> comments;
    if (!m_isConnected || !m_db.isOpen() || bookId <= 0) {
        qWarning() << "Неможливо отримати коментарі: немає з'єднання або невірний bookId.";
        return comments;
    }

    const QString sql = getSqlQuery("GetBookCommentsByBookId");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetBookCommentsByBookId' не знайдено.";
        return comments;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'GetBookCommentsByBookId':" << query.lastError().text();
        return comments;
    }
    query.bindValue(":bookId", bookId);

    qInfo() << "Виконання SQL 'GetBookCommentsByBookId' для book ID:" << bookId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'GetBookCommentsByBookId' для book ID '" << bookId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        return comments;
    }

    qInfo() << "Коментарі успішно отримано. Обробка результатів...";
    int count = 0;
    while (query.next()) {
        CommentDisplayInfo commentInfo;
        commentInfo.authorName = query.value("author_name").toString();
        commentInfo.commentDate = query.value("comment_date").toDateTime();
        QVariant ratingValue = query.value("rating");
        commentInfo.rating = ratingValue.isNull() ? 0 : ratingValue.toInt();
        commentInfo.commentText = query.value("comment_text").toString();

        comments.append(commentInfo);
        count++;
    }
    qInfo() << "Оброблено" << count << "коментарів для book ID" << bookId;

    return comments;
}
