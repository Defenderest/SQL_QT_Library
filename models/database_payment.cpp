#include "database.h"

#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>

bool DatabaseManager::createPaymentTransaction(const PaymentTransactionCreateInfo& info, int& paymentTransactionId)
{
    paymentTransactionId = -1;

    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot create payment transaction: no database connection.";
        return false;
    }

    if (info.customerId <= 0 || info.providerOrderId.trimmed().isEmpty() ||
        info.amount < 0.0 || info.currency.trimmed().isEmpty()) {
        qWarning() << "Cannot create payment transaction: invalid input.";
        return false;
    }

    const QString insertSql = getSqlQuery("InsertPaymentTransaction");
    const QString historySql = getSqlQuery("InsertPaymentStatusHistoryByTransactionId");
    if (insertSql.isEmpty() || historySql.isEmpty()) {
        return false;
    }

    QSqlQuery insertQuery(m_db);
    if (!insertQuery.prepare(insertSql)) {
        qCritical() << "Failed to prepare 'InsertPaymentTransaction':" << insertQuery.lastError().text();
        return false;
    }

    insertQuery.bindValue(":provider", info.provider.trimmed().isEmpty() ? QStringLiteral("liqpay") : info.provider.trimmed());
    insertQuery.bindValue(":provider_order_id", info.providerOrderId.trimmed());
    insertQuery.bindValue(":customer_id", info.customerId);
    insertQuery.bindValue(":amount", info.amount);
    insertQuery.bindValue(":currency", info.currency.trimmed().toUpper());
    insertQuery.bindValue(":status", info.status.trimmed().isEmpty() ? QStringLiteral("created") : info.status.trimmed());
    insertQuery.bindValue(":checkout_url", info.checkoutUrl.trimmed().isEmpty() ? QVariant(QVariant::String) : info.checkoutUrl.trimmed());
    insertQuery.bindValue(":request_data_base64", info.requestDataBase64.trimmed().isEmpty() ? QVariant(QVariant::String) : info.requestDataBase64.trimmed());
    insertQuery.bindValue(":request_signature", info.requestSignature.trimmed().isEmpty() ? QVariant(QVariant::String) : info.requestSignature.trimmed());

    QVariant insertedId;
    if (!executeInsertQuery(insertQuery, "InsertPaymentTransaction", insertedId)) {
        return false;
    }

    paymentTransactionId = insertedId.toInt();
    if (paymentTransactionId <= 0) {
        qCritical() << "InsertPaymentTransaction returned invalid transaction id.";
        return false;
    }

    QSqlQuery historyQuery(m_db);
    if (!historyQuery.prepare(historySql)) {
        qCritical() << "Failed to prepare 'InsertPaymentStatusHistoryByTransactionId':" << historyQuery.lastError().text();
        return false;
    }

    historyQuery.bindValue(":payment_transaction_id", paymentTransactionId);
    historyQuery.bindValue(":status", info.status.trimmed().isEmpty() ? QStringLiteral("created") : info.status.trimmed());
    historyQuery.bindValue(":details", QStringLiteral("Transaction created"));
    if (!historyQuery.exec()) {
        qCritical() << "Failed to execute 'InsertPaymentStatusHistoryByTransactionId':" << historyQuery.lastError().text();
        return false;
    }

    return historyQuery.numRowsAffected() > 0;
}

PaymentTransactionRecord DatabaseManager::getPaymentTransactionByProviderOrderId(const QString& providerOrderId) const
{
    PaymentTransactionRecord result;

    if (!m_isConnected || !m_db.isOpen() || providerOrderId.trimmed().isEmpty()) {
        return result;
    }

    const QString sql = getSqlQuery("GetPaymentTransactionByProviderOrderId");
    if (sql.isEmpty()) {
        return result;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'GetPaymentTransactionByProviderOrderId':" << query.lastError().text();
        return result;
    }

    query.bindValue(":provider_order_id", providerOrderId.trimmed());
    if (!query.exec()) {
        qCritical() << "Failed to execute 'GetPaymentTransactionByProviderOrderId':" << query.lastError().text();
        return result;
    }

    if (!query.next()) {
        return result;
    }

    result.paymentTransactionId = query.value("payment_transaction_id").toInt();
    result.customerId = query.value("customer_id").toInt();
    result.orderId = query.value("order_id").toInt();
    result.provider = query.value("provider").toString();
    result.providerOrderId = query.value("provider_order_id").toString();
    result.amount = query.value("amount").toDouble();
    result.currency = query.value("currency").toString();
    result.status = query.value("status").toString();
    result.found = true;
    return result;
}

bool DatabaseManager::updatePaymentTransactionStatus(const QString& providerOrderId,
                                                     const QString& status,
                                                     const QString& responseDataBase64,
                                                     const QString& responseSignature,
                                                     const QString& providerPaymentId,
                                                     bool markVerified)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot update payment transaction: no database connection.";
        return false;
    }

    if (providerOrderId.trimmed().isEmpty() || status.trimmed().isEmpty()) {
        return false;
    }

    const QString sql = getSqlQuery("UpdatePaymentTransactionStatusByProviderOrderId");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'UpdatePaymentTransactionStatusByProviderOrderId':" << query.lastError().text();
        return false;
    }

    query.bindValue(":provider_order_id", providerOrderId.trimmed());
    query.bindValue(":status", status.trimmed());
    query.bindValue(":response_data_base64", responseDataBase64.trimmed().isEmpty()
                    ? QVariant(QVariant::String)
                    : responseDataBase64.trimmed());
    query.bindValue(":response_signature", responseSignature.trimmed().isEmpty()
                    ? QVariant(QVariant::String)
                    : responseSignature.trimmed());
    query.bindValue(":provider_payment_id", providerPaymentId.trimmed().isEmpty()
                    ? QVariant(QVariant::String)
                    : providerPaymentId.trimmed());
    query.bindValue(":mark_verified", markVerified);

    if (!query.exec()) {
        qCritical() << "Failed to execute 'UpdatePaymentTransactionStatusByProviderOrderId':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool DatabaseManager::appendPaymentStatusHistory(const QString& providerOrderId,
                                                 const QString& status,
                                                 const QString& details)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot append payment status history: no database connection.";
        return false;
    }

    if (providerOrderId.trimmed().isEmpty() || status.trimmed().isEmpty()) {
        return false;
    }

    const QString sql = getSqlQuery("InsertPaymentStatusHistoryByProviderOrderId");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'InsertPaymentStatusHistoryByProviderOrderId':" << query.lastError().text();
        return false;
    }

    query.bindValue(":provider_order_id", providerOrderId.trimmed());
    query.bindValue(":status", status.trimmed());
    query.bindValue(":details", details.trimmed().isEmpty() ? QVariant(QVariant::String) : details.trimmed());
    if (!query.exec()) {
        qCritical() << "Failed to execute 'InsertPaymentStatusHistoryByProviderOrderId':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool DatabaseManager::linkPaymentTransactionToOrder(const QString& providerOrderId, int orderId)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot link payment transaction to order: no database connection.";
        return false;
    }

    if (providerOrderId.trimmed().isEmpty() || orderId <= 0) {
        return false;
    }

    const QString sql = getSqlQuery("UpdatePaymentTransactionOrderLink");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'UpdatePaymentTransactionOrderLink':" << query.lastError().text();
        return false;
    }

    query.bindValue(":provider_order_id", providerOrderId.trimmed());
    query.bindValue(":order_id", orderId);
    if (!query.exec()) {
        qCritical() << "Failed to execute 'UpdatePaymentTransactionOrderLink':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}
