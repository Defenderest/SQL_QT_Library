#include "cartmodel.h"
#include "../core/database.h"
#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QEventLoop>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QStringList>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>

namespace {
constexpr int kBookReservationHoldMinutes = 15;

QString normalizeLiqPayValue(const QString& rawValue)
{
    QString value = rawValue.trimmed();
    if (value.length() >= 2) {
        const QChar first = value.front();
        const QChar last = value.back();
        if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
            value = value.mid(1, value.length() - 2).trimmed();
        }
    }
    return value;
}

QString readFirstEnvValue(const QStringList& names)
{
    for (const QString& name : names) {
        const QByteArray nameBytes = name.toUtf8();
        const QString value = normalizeLiqPayValue(qEnvironmentVariable(nameBytes.constData()));
        if (!value.isEmpty()) {
            return value;
        }
    }
    return QString();
}

bool validateShippingAddress(const QString& address, QString* errorMessage)
{
    const QString normalized = address.simplified();
    if (normalized.isEmpty()) {
        if (errorMessage) {
            *errorMessage = "Вкажіть адресу доставки";
        }
        return false;
    }

    if (normalized.length() < 8) {
        if (errorMessage) {
            *errorMessage = "Адреса занадто коротка";
        }
        return false;
    }

    if (normalized.length() > 180) {
        if (errorMessage) {
            *errorMessage = "Адреса занадто довга";
        }
        return false;
    }

    static const QRegularExpression hasLetter(QStringLiteral("[\\p{L}]") );
    if (!hasLetter.match(normalized).hasMatch()) {
        if (errorMessage) {
            *errorMessage = "Адреса має містити назву вулиці";
        }
        return false;
    }

    static const QRegularExpression hasHouseNumber(QStringLiteral("\\d"));
    if (!hasHouseNumber.match(normalized).hasMatch()) {
        if (errorMessage) {
            *errorMessage = "Вкажіть номер будинку";
        }
        return false;
    }

    static const QRegularExpression allowedChars(
        QStringLiteral("^[\\p{L}0-9\\s\\.,'\"\\-\\/()]+$"));
    if (!allowedChars.match(normalized).hasMatch()) {
        if (errorMessage) {
            *errorMessage = "Адреса містить недопустимі символи";
        }
        return false;
    }

    return true;
}

double parseLiqPayAmount(const QJsonObject& payload)
{
    const QJsonValue amountValue = payload.value(QStringLiteral("amount"));
    if (amountValue.isDouble()) {
        return amountValue.toDouble();
    }

    if (amountValue.isString()) {
        QString asText = amountValue.toString().trimmed();
        asText.replace(',', '.');
        bool ok = false;
        const double parsed = asText.toDouble(&ok);
        return ok ? parsed : -1.0;
    }

    return -1.0;
}

QString finalFailureReservationMessage(const QString& status)
{
    return QStringLiteral("Платіж не підтверджено. Бронь книг знято. Статус: %1").arg(status);
}
}

CartModel::CartModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int CartModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_items.count();
}

QVariant CartModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.count())
        return QVariant();

    const CartItem &item = m_items.at(index.row());

    switch (role) {
    case BookIdRole:
        return item.bookId;
    case TitleRole:
        return item.title;
    case AuthorRole:
        return item.author;
    case PriceRole:
        return item.price;
    case QuantityRole:
        return item.quantity;
    case CoverImagePathRole:
        return item.coverImagePath;
    case SubtotalRole:
        return item.price * item.quantity;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> CartModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[BookIdRole] = "bookId";
    roles[TitleRole] = "title";
    roles[AuthorRole] = "author";
    roles[PriceRole] = "price";
    roles[QuantityRole] = "quantity";
    roles[CoverImagePathRole] = "coverImagePath";
    roles[SubtotalRole] = "subtotal";
    return roles;
}

DatabaseManager* CartModel::dbManager() const
{
    return m_dbManager;
}

void CartModel::setDbManager(DatabaseManager* dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
    }
}

int CartModel::customerId() const
{
    return m_customerId;
}

void CartModel::setCustomerId(int customerId)
{
    if (m_customerId != customerId) {
        m_customerId = customerId;
        clearPendingLiqPayState();
        emit customerIdChanged();
        loadCart();
    }
}

int CartModel::totalItems() const
{
    int total = 0;
    for (const auto& item : m_items) {
        total += item.quantity;
    }
    return total;
}

double CartModel::totalPrice() const
{
    double total = 0.0;
    for (const auto& item : m_items) {
        total += item.price * item.quantity;
    }
    return total;
}

void CartModel::loadCart()
{
    if (!m_dbManager || m_customerId <= 0) {
        beginResetModel();
        m_items.clear();
        endResetModel();
        recalculateTotals();
        return;
    }

    const QMap<int, int> dbItems = m_dbManager->getCartItems(m_customerId);

    beginResetModel();
    m_items.clear();
    for (auto it = dbItems.constBegin(); it != dbItems.constEnd(); ++it) {
        const int bookId = it.key();
        const int quantity = it.value();
        if (bookId <= 0 || quantity <= 0) {
            continue;
        }

        const BookDisplayInfo bookInfo = m_dbManager->getBookDisplayInfoById(bookId);
        if (!bookInfo.found) {
            qWarning() << "CartModel: book not found for cart item, bookId =" << bookId;
            continue;
        }

        CartItem item;
        item.bookId = bookId;
        item.title = bookInfo.title;
        item.author = bookInfo.authors;
        item.price = bookInfo.price;
        item.quantity = quantity;
        item.coverImagePath = bookInfo.coverImagePath;
        m_items.append(item);
    }
    endResetModel();

    recalculateTotals();
}

QString CartModel::liqPayPublicKey() const
{
    return m_liqPayPublicKey;
}

void CartModel::setLiqPayPublicKey(const QString& publicKey)
{
    const QString normalized = publicKey.trimmed();
    if (m_liqPayPublicKey == normalized) {
        return;
    }
    m_liqPayPublicKey = normalized;
    emit liqPayConfigChanged();
}

QString CartModel::liqPayPrivateKey() const
{
    return m_liqPayPrivateKey;
}

void CartModel::setLiqPayPrivateKey(const QString& privateKey)
{
    const QString normalized = privateKey.trimmed();
    if (m_liqPayPrivateKey == normalized) {
        return;
    }
    m_liqPayPrivateKey = normalized;
    emit liqPayConfigChanged();
}

void CartModel::addItem(int bookId)
{
    if (!m_dbManager) {
        emit errorOccurred("Помилка підключення до бази даних");
        return;
    }
    if (m_customerId <= 0) {
        emit errorOccurred("Щоб додавати книги в кошик, увійдіть у профіль");
        return;
    }

    int newQuantity = 1;
    for (int i = 0; i < m_items.count(); ++i) {
        if (m_items[i].bookId == bookId) {
            newQuantity = m_items[i].quantity + 1;
            break;
        }
    }

    if (!m_dbManager->addOrUpdateCartItem(m_customerId, bookId, newQuantity)) {
        emit errorOccurred("Failed to add item to cart");
        return;
    }

    loadCart();

    for (const auto& item : m_items) {
        if (item.bookId == bookId) {
            emit itemAdded(item.title);
            break;
        }
    }
}

void CartModel::removeItem(int bookId)
{
    if (!m_dbManager) {
        emit errorOccurred("Помилка підключення до бази даних");
        return;
    }
    if (m_customerId <= 0) {
        emit errorOccurred("Щоб працювати з кошиком, увійдіть у профіль");
        return;
    }

    if (!m_dbManager->removeCartItem(m_customerId, bookId)) {
        emit errorOccurred("Failed to remove item from cart");
        return;
    }

    loadCart();
}

void CartModel::increaseQuantity(int bookId)
{
    if (!m_dbManager) {
        emit errorOccurred("Помилка підключення до бази даних");
        return;
    }
    if (m_customerId <= 0) {
        emit errorOccurred("Щоб працювати з кошиком, увійдіть у профіль");
        return;
    }

    for (int i = 0; i < m_items.count(); ++i) {
        if (m_items[i].bookId == bookId) {
            const int newQuantity = m_items[i].quantity + 1;
            if (!m_dbManager->addOrUpdateCartItem(m_customerId, bookId, newQuantity)) {
                emit errorOccurred("Failed to update cart item quantity");
                return;
            }
            loadCart();
            return;
        }
    }
}

void CartModel::decreaseQuantity(int bookId)
{
    if (!m_dbManager) {
        emit errorOccurred("Помилка підключення до бази даних");
        return;
    }
    if (m_customerId <= 0) {
        emit errorOccurred("Щоб працювати з кошиком, увійдіть у профіль");
        return;
    }

    for (int i = 0; i < m_items.count(); ++i) {
        if (m_items[i].bookId == bookId) {
            if (m_items[i].quantity > 1) {
                const int newQuantity = m_items[i].quantity - 1;
                if (!m_dbManager->addOrUpdateCartItem(m_customerId, bookId, newQuantity)) {
                    emit errorOccurred("Failed to update cart item quantity");
                    return;
                }
            } else {
                if (!m_dbManager->removeCartItem(m_customerId, bookId)) {
                    emit errorOccurred("Failed to remove item from cart");
                    return;
                }
            }
            loadCart();
            return;
        }
    }
}

void CartModel::clearCart()
{
    if (!m_dbManager || m_customerId <= 0) {
        beginResetModel();
        m_items.clear();
        endResetModel();
        recalculateTotals();
        return;
    }

    if (!m_dbManager->clearCart(m_customerId)) {
        emit errorOccurred("Failed to clear cart");
        return;
    }

    loadCart();
}

bool CartModel::checkout(const QString& shippingAddress,
                         const QString& paymentMethod,
                         const QString& reservationProviderOrderId)
{
    m_lastCheckoutOrderId = -1;

    if (!m_dbManager) {
        const QString message = "Помилка підключення до бази даних";
        emit errorOccurred(message);
        emit checkoutFailed(message);
        return false;
    }
    if (m_customerId <= 0) {
        const QString message = "Щоб оформити замовлення, увійдіть у профіль";
        emit errorOccurred(message);
        emit checkoutFailed(message);
        return false;
    }

    const QString cleanAddress = shippingAddress.simplified();
    QString addressError;
    if (!validateShippingAddress(cleanAddress, &addressError)) {
        const QString message = addressError;
        emit errorOccurred(message);
        emit checkoutFailed(message);
        return false;
    }

    if (m_items.isEmpty()) {
        const QString message = "Cart is empty";
        emit checkoutFailed(message);
        return false;
    }

    QMap<int, int> itemsToOrder;
    for (const auto& item : m_items) {
        if (item.bookId > 0 && item.quantity > 0) {
            itemsToOrder[item.bookId] = item.quantity;
        }
    }

    if (itemsToOrder.isEmpty()) {
        const QString message = "Cart contains no valid items";
        emit checkoutFailed(message);
        return false;
    }

    const QString reservationToken = reservationProviderOrderId.trimmed();
    if (reservationToken.isEmpty()) {
        for (auto it = itemsToOrder.constBegin(); it != itemsToOrder.constEnd(); ++it) {
            const BookDisplayInfo bookInfo = m_dbManager->getBookDisplayInfoById(it.key());
            if (!bookInfo.found) {
                const QString message = "Одна з книг у кошику більше недоступна";
                emit errorOccurred(message);
                emit checkoutFailed(message);
                return false;
            }

            if (it.value() > bookInfo.stockQuantity) {
                const QString message = QStringLiteral("Книга \"%1\" вже недоступна у потрібній кількості")
                                            .arg(bookInfo.title);
                emit errorOccurred(message);
                emit checkoutFailed(message);
                return false;
            }
        }
    }

    int newOrderId = -1;
    const double total = m_dbManager->createOrder(
        m_customerId,
        itemsToOrder,
        cleanAddress,
        paymentMethod.trimmed(),
        newOrderId,
        reservationToken
    );

    if (total < 0.0 || newOrderId <= 0) {
        const QString message = "Failed to create order";
        emit errorOccurred(message);
        emit checkoutFailed(message);
        return false;
    }

    m_lastCheckoutOrderId = newOrderId;
    loadCart();
    emit checkoutSucceeded(newOrderId);
    return true;
}

void CartModel::startLiqPayCheckout(const QString& shippingAddress)
{
    if (!m_dbManager) {
        emit liqPayCheckoutFailed("Помилка підключення до бази даних");
        return;
    }

    if (m_customerId <= 0) {
        emit liqPayCheckoutFailed("Користувач не авторизований");
        return;
    }

    const QString cleanAddress = shippingAddress.simplified();
    QString addressError;
    if (!validateShippingAddress(cleanAddress, &addressError)) {
        emit liqPayCheckoutFailed(addressError);
        return;
    }

    if (m_items.isEmpty()) {
        emit liqPayCheckoutFailed("Кошик порожній");
        return;
    }

    bool configUpdated = false;
    if (m_liqPayPublicKey.trimmed().isEmpty()) {
        const QString fromEnv = readFirstEnvValue(QStringList{
            QStringLiteral("LIQPAY_PUBLIC_KEY"),
            QStringLiteral("LIQPAY_SANDBOX_PUBLIC_KEY"),
            QStringLiteral("LIQPAY_PUBLIC"),
            QStringLiteral("LIQPAY_SANDBOX_PUBLIC"),
            QStringLiteral("LIQPAY_PUBLICKEY"),
            QStringLiteral("PUBLIC_KEY")
        });
        if (!fromEnv.isEmpty()) {
            m_liqPayPublicKey = fromEnv;
            configUpdated = true;
        }
    }

    if (m_liqPayPrivateKey.trimmed().isEmpty()) {
        const QString fromEnv = readFirstEnvValue(QStringList{
            QStringLiteral("LIQPAY_PRIVATE_KEY"),
            QStringLiteral("LIQPAY_SANDBOX_PRIVATE_KEY"),
            QStringLiteral("LIQPAY_PRIVATE"),
            QStringLiteral("LIQPAY_SANDBOX_PRIVATE"),
            QStringLiteral("LIQPAY_PRIVATEKEY"),
            QStringLiteral("PRIVATE_KEY")
        });
        if (!fromEnv.isEmpty()) {
            m_liqPayPrivateKey = fromEnv;
            configUpdated = true;
        }
    }

    if (configUpdated) {
        emit liqPayConfigChanged();
    }

    if (m_liqPayPublicKey.trimmed().isEmpty() || m_liqPayPrivateKey.trimmed().isEmpty()) {
        emit liqPayCheckoutFailed("Не знайдено ключі LiqPay. Використайте LIQPAY_PUBLIC_KEY/LIQPAY_PRIVATE_KEY (або LIQPAY_SANDBOX_*, LIQPAY_PUBLIC/PRIVATE, PUBLIC_KEY/PRIVATE_KEY), або передайте --liqpay-public-key/--liqpay-private-key, або додайте .env файл");
        return;
    }

    QMap<int, int> itemsToReserve;
    for (const auto& item : m_items) {
        if (item.bookId > 0 && item.quantity > 0) {
            itemsToReserve[item.bookId] = item.quantity;
        }
    }

    if (itemsToReserve.isEmpty()) {
        emit liqPayCheckoutFailed("У кошику немає коректних позицій для бронювання");
        return;
    }

    if (!m_pendingLiqPayProviderOrderId.trimmed().isEmpty()) {
        m_dbManager->updatePaymentTransactionStatus(m_pendingLiqPayProviderOrderId,
                                                    QStringLiteral("replaced"));
        m_dbManager->appendPaymentStatusHistory(m_pendingLiqPayProviderOrderId,
                                                QStringLiteral("replaced"),
                                                QStringLiteral("Replaced by a newer checkout session"));
        m_dbManager->releaseBookReservationByProviderOrderId(m_pendingLiqPayProviderOrderId,
                                                             QStringLiteral("replaced"));
        clearPendingLiqPayState();
    }

    const QString providerOrderId = QString("COURSE_%1_%2")
        .arg(m_customerId)
        .arg(QDateTime::currentMSecsSinceEpoch());

    QString requestDataBase64;
    QString requestSignature;
    const QString checkoutUrl = buildLiqPayCheckoutUrl(cleanAddress,
                                                       providerOrderId,
                                                       &requestDataBase64,
                                                       &requestSignature);
    if (checkoutUrl.isEmpty()) {
        emit liqPayCheckoutFailed("Не вдалося сформувати посилання LiqPay");
        return;
    }

    PaymentTransactionCreateInfo paymentInfo;
    paymentInfo.customerId = m_customerId;
    paymentInfo.provider = QStringLiteral("liqpay");
    paymentInfo.providerOrderId = providerOrderId;
    paymentInfo.amount = totalPrice();
    paymentInfo.currency = QStringLiteral("UAH");
    paymentInfo.status = QStringLiteral("checkout_opened");
    paymentInfo.checkoutUrl = checkoutUrl;
    paymentInfo.requestDataBase64 = requestDataBase64;
    paymentInfo.requestSignature = requestSignature;

    QString reservationError;
    if (!m_dbManager->createBookReservation(m_customerId,
                                            providerOrderId,
                                            itemsToReserve,
                                            kBookReservationHoldMinutes,
                                            &reservationError)) {
        emit liqPayCheckoutFailed(reservationError.isEmpty()
                                      ? QStringLiteral("Не вдалося забронювати книги на час оплати")
                                      : reservationError);
        return;
    }

    int paymentTransactionId = -1;
    if (!m_dbManager->createPaymentTransaction(paymentInfo, paymentTransactionId)) {
        m_dbManager->releaseBookReservationByProviderOrderId(providerOrderId,
                                                             QStringLiteral("payment_transaction_failed"));
        emit liqPayCheckoutFailed("Не вдалося створити платіжну транзакцію");
        return;
    }
    Q_UNUSED(paymentTransactionId)

    m_pendingLiqPayProviderOrderId = providerOrderId;
    m_pendingLiqPayShippingAddress = cleanAddress;
    m_pendingLiqPayExpectedAmount = paymentInfo.amount;
    m_pendingLiqPayCurrency = paymentInfo.currency;

    emit liqPayCheckoutOpened(checkoutUrl);
}

QString CartModel::buildLiqPayCheckoutUrl(const QString& shippingAddress,
                                          const QString& orderId,
                                          QString* outDataBase64,
                                          QString* outSignature) const
{
    if (m_liqPayPublicKey.trimmed().isEmpty() || m_liqPayPrivateKey.trimmed().isEmpty()) {
        return QString();
    }

    const QString totalAmount = QString::number(totalPrice(), 'f', 2);
    const QString description = QString("Курсова: замовлення книг, адреса: %1").arg(shippingAddress);

    QJsonObject payload;
    payload["public_key"] = m_liqPayPublicKey;
    payload["version"] = "3";
    payload["action"] = "pay";
    payload["amount"] = totalAmount;
    payload["currency"] = "UAH";
    payload["description"] = description;
    payload["order_id"] = orderId;
    payload["sandbox"] = "1";
    payload["language"] = "uk";
    payload["result_url"] = "https://liqpay.local/result";
    payload["server_url"] = "https://liqpay.local/server";

    const QByteArray jsonPayload = QJsonDocument(payload).toJson(QJsonDocument::Compact);
    const QByteArray dataBase64 = jsonPayload.toBase64();
    const QByteArray signature = buildLiqPaySignature(m_liqPayPrivateKey, dataBase64);

    if (outDataBase64) {
        *outDataBase64 = QString::fromUtf8(dataBase64);
    }
    if (outSignature) {
        *outSignature = QString::fromUtf8(signature);
    }

    QString url = "https://www.liqpay.ua/api/3/checkout";
    url += "?data=" + QString::fromUtf8(QUrl::toPercentEncoding(QString::fromUtf8(dataBase64)));
    url += "&signature=" + QString::fromUtf8(QUrl::toPercentEncoding(QString::fromUtf8(signature)));
    return url;
}

void CartModel::verifyPendingLiqPayPayment(const QString& callbackUrl)
{
    if (!m_dbManager) {
        emit liqPayCheckoutFailed("Помилка підключення до бази даних");
        return;
    }

    if (m_pendingLiqPayProviderOrderId.trimmed().isEmpty()) {
        emit liqPayCheckoutFailed("Немає активної LiqPay транзакції для перевірки");
        return;
    }

    const QString providerOrderId = m_pendingLiqPayProviderOrderId;
    const PaymentTransactionRecord paymentTx =
        m_dbManager->getPaymentTransactionByProviderOrderId(providerOrderId);
    if (!paymentTx.found) {
        emit liqPayCheckoutFailed("Платіжну транзакцію не знайдено");
        clearPendingLiqPayState();
        return;
    }

    if (paymentTx.orderId > 0) {
        emit checkoutSucceeded(paymentTx.orderId);
        clearPendingLiqPayState();
        return;
    }

    const auto failReservationValidation = [this, &providerOrderId](const QString& paymentStatus,
                                                                    const QString& historyDetails,
                                                                    const QString& userMessage,
                                                                    const QString& responseDataBase64 = QString(),
                                                                    const QString& responseSignature = QString(),
                                                                    const QString& providerPaymentId = QString(),
                                                                    bool markVerified = false) {
        m_dbManager->updatePaymentTransactionStatus(providerOrderId,
                                                    paymentStatus,
                                                    responseDataBase64,
                                                    responseSignature,
                                                    providerPaymentId,
                                                    markVerified);
        m_dbManager->appendPaymentStatusHistory(providerOrderId,
                                                paymentStatus,
                                                historyDetails);
        m_dbManager->releaseBookReservationByProviderOrderId(providerOrderId,
                                                             QStringLiteral("payment_validation_failed"));
        clearPendingLiqPayState();
        emit liqPayCheckoutFailed(userMessage);
    };

    QString status;
    QString providerPaymentId;
    double amount = -1.0;
    QString currency;
    QString responseDataBase64;
    QString responseSignature;
    bool signatureVerified = false;

    const QString trimmedCallbackUrl = callbackUrl.trimmed();
    if (!trimmedCallbackUrl.isEmpty()) {
        const QUrl parsedUrl(trimmedCallbackUrl);
        const QUrlQuery query(parsedUrl);
        const QString dataParam = normalizeBase64QueryValue(query.queryItemValue(QStringLiteral("data")));
        const QString signatureParam = normalizeBase64QueryValue(query.queryItemValue(QStringLiteral("signature")));

        if (!dataParam.isEmpty() && !signatureParam.isEmpty()) {
            responseDataBase64 = dataParam;
            responseSignature = signatureParam;

            if (!verifyLiqPayCallbackSignature(dataParam, signatureParam)) {
                m_dbManager->updatePaymentTransactionStatus(providerOrderId,
                                                            QStringLiteral("signature_invalid"),
                                                            responseDataBase64,
                                                            responseSignature,
                                                            QString(),
                                                            false);
                m_dbManager->appendPaymentStatusHistory(providerOrderId,
                                                        QStringLiteral("signature_invalid"),
                                                        QStringLiteral("LiqPay callback signature mismatch"));
                emit liqPayCheckoutFailed("Не вдалося перевірити підпис LiqPay");
                return;
            }

            const QByteArray decodedData = QByteArray::fromBase64(dataParam.toUtf8());
            const QJsonDocument callbackDoc = QJsonDocument::fromJson(decodedData);
            if (!callbackDoc.isObject()) {
                m_dbManager->updatePaymentTransactionStatus(providerOrderId,
                                                            QStringLiteral("invalid_callback_payload"),
                                                            responseDataBase64,
                                                            responseSignature,
                                                            QString(),
                                                            false);
                m_dbManager->appendPaymentStatusHistory(providerOrderId,
                                                        QStringLiteral("invalid_callback_payload"),
                                                        QStringLiteral("Unable to parse callback JSON payload"));
                emit liqPayCheckoutFailed("Некоректна відповідь LiqPay");
                return;
            }

            const QJsonObject callbackPayload = callbackDoc.object();
            const QString callbackOrderId = callbackPayload.value(QStringLiteral("order_id")).toString().trimmed();
            if (callbackOrderId != providerOrderId) {
                failReservationValidation(QStringLiteral("order_mismatch"),
                                          QStringLiteral("Callback order_id does not match pending transaction"),
                                          QStringLiteral("LiqPay повернув інший order_id"),
                                          responseDataBase64,
                                          responseSignature);
                return;
            }

            status = callbackPayload.value(QStringLiteral("status")).toString().trimmed().toLower();
            providerPaymentId = callbackPayload.value(QStringLiteral("transaction_id")).toVariant().toString().trimmed();
            amount = parseLiqPayAmount(callbackPayload);
            currency = callbackPayload.value(QStringLiteral("currency")).toString().trimmed().toUpper();
            signatureVerified = true;
        }
    }

    if (!signatureVerified) {
        QString statusError;
        const QJsonObject statusPayload = requestLiqPayStatus(providerOrderId, &statusError);
        if (statusPayload.isEmpty()) {
            m_dbManager->updatePaymentTransactionStatus(providerOrderId,
                                                        QStringLiteral("verification_failed"),
                                                        QString(),
                                                        QString(),
                                                        QString(),
                                                        false);
            m_dbManager->appendPaymentStatusHistory(providerOrderId,
                                                    QStringLiteral("verification_failed"),
                                                    statusError.isEmpty() ? QStringLiteral("Unable to verify payment status") : statusError);
            emit liqPayCheckoutFailed(statusError.isEmpty() ? QStringLiteral("Не вдалося перевірити статус платежу") : statusError);
            return;
        }

        const QString statusOrderId = statusPayload.value(QStringLiteral("order_id")).toString().trimmed();
        if (statusOrderId != providerOrderId) {
            failReservationValidation(QStringLiteral("order_mismatch"),
                                      QStringLiteral("Status API returned mismatched order_id"),
                                      QStringLiteral("Невідповідний order_id у статусі LiqPay"));
            return;
        }

        status = statusPayload.value(QStringLiteral("status")).toString().trimmed().toLower();
        providerPaymentId = statusPayload.value(QStringLiteral("transaction_id")).toVariant().toString().trimmed();
        amount = parseLiqPayAmount(statusPayload);
        currency = statusPayload.value(QStringLiteral("currency")).toString().trimmed().toUpper();
        responseDataBase64 = QString::fromUtf8(
            QJsonDocument(statusPayload).toJson(QJsonDocument::Compact).toBase64());
    }

    if (amount >= 0.0 && m_pendingLiqPayExpectedAmount > 0.0 &&
        qAbs(amount - m_pendingLiqPayExpectedAmount) > 0.01) {
        failReservationValidation(QStringLiteral("amount_mismatch"),
                                  QStringLiteral("Expected amount does not match LiqPay response"),
                                  QStringLiteral("Сума платежу не збігається із замовленням"),
                                  responseDataBase64,
                                  responseSignature,
                                  providerPaymentId,
                                  signatureVerified);
        return;
    }

    if (!currency.isEmpty() && !m_pendingLiqPayCurrency.trimmed().isEmpty() &&
        currency.toUpper() != m_pendingLiqPayCurrency.trimmed().toUpper()) {
        failReservationValidation(QStringLiteral("currency_mismatch"),
                                  QStringLiteral("Expected currency does not match LiqPay response"),
                                  QStringLiteral("Валюта платежу не збігається із замовленням"),
                                  responseDataBase64,
                                  responseSignature,
                                  providerPaymentId,
                                  signatureVerified);
        return;
    }

    const QString normalizedStatus = status.isEmpty() ? QStringLiteral("unknown") : status;
    m_dbManager->updatePaymentTransactionStatus(providerOrderId,
                                                normalizedStatus,
                                                responseDataBase64,
                                                responseSignature,
                                                providerPaymentId,
                                                signatureVerified);
    m_dbManager->appendPaymentStatusHistory(providerOrderId,
                                            normalizedStatus,
                                            signatureVerified
                                                ? QStringLiteral("Verified by callback signature")
                                                : QStringLiteral("Verified through LiqPay status API"));

    if (!isSuccessfulLiqPayStatus(normalizedStatus)) {
        if (isTerminalFailedLiqPayStatus(normalizedStatus)) {
            m_dbManager->releaseBookReservationByProviderOrderId(providerOrderId,
                                                                 QStringLiteral("payment_failed"));
            clearPendingLiqPayState();
            emit liqPayCheckoutFailed(finalFailureReservationMessage(normalizedStatus));
            return;
        }

        emit liqPayCheckoutFailed(QStringLiteral("Платіж ще не підтверджено. Бронь зберігається. Статус: %1").arg(normalizedStatus));
        return;
    }

    if (!checkout(m_pendingLiqPayShippingAddress,
                  QStringLiteral("LiqPay Sandbox"),
                  providerOrderId)) {
        m_dbManager->updatePaymentTransactionStatus(providerOrderId,
                                                    QStringLiteral("order_creation_failed"),
                                                    responseDataBase64,
                                                    responseSignature,
                                                    providerPaymentId,
                                                    signatureVerified);
        m_dbManager->appendPaymentStatusHistory(providerOrderId,
                                                QStringLiteral("order_creation_failed"),
                                                QStringLiteral("Payment verified but order creation failed"));
        return;
    }

    if (m_lastCheckoutOrderId > 0) {
        if (!m_dbManager->linkPaymentTransactionToOrder(providerOrderId, m_lastCheckoutOrderId)) {
            qWarning() << "Failed to link payment transaction to order" << providerOrderId << m_lastCheckoutOrderId;
        }
        if (!m_dbManager->appendPaymentStatusHistory(providerOrderId,
                                                     QStringLiteral("order_created"),
                                                     QStringLiteral("Order #%1 created").arg(m_lastCheckoutOrderId))) {
            qWarning() << "Failed to append payment history for created order" << providerOrderId;
        }
        if (!m_dbManager->addOrderStatusByAdmin(m_lastCheckoutOrderId, QStringLiteral("Оплачено"))) {
            qWarning() << "Failed to append paid order status" << m_lastCheckoutOrderId;
        }
        if (!m_dbManager->updatePaymentTransactionStatus(providerOrderId,
                                                         QStringLiteral("paid"),
                                                         responseDataBase64,
                                                         responseSignature,
                                                         providerPaymentId,
                                                         true)) {
            qWarning() << "Failed to finalize payment transaction status as paid" << providerOrderId;
        }
    }

    clearPendingLiqPayState();
}

void CartModel::cancelPendingLiqPayCheckout()
{
    if (m_pendingLiqPayProviderOrderId.trimmed().isEmpty()) {
        return;
    }

    if (m_dbManager) {
        m_dbManager->releaseBookReservationByProviderOrderId(m_pendingLiqPayProviderOrderId,
                                                             QStringLiteral("user_canceled"));
        m_dbManager->updatePaymentTransactionStatus(m_pendingLiqPayProviderOrderId,
                                                    QStringLiteral("user_canceled"));
        m_dbManager->appendPaymentStatusHistory(m_pendingLiqPayProviderOrderId,
                                                QStringLiteral("user_canceled"),
                                                QStringLiteral("Checkout canceled by user"));
    }

    clearPendingLiqPayState();
}

bool CartModel::isSuccessfulLiqPayStatus(const QString& status) const
{
    const QString normalized = status.trimmed().toLower();
    return normalized == QStringLiteral("success") ||
           normalized == QStringLiteral("sandbox");
}

bool CartModel::isTerminalFailedLiqPayStatus(const QString& status) const
{
    const QString normalized = status.trimmed().toLower();
    return normalized == QStringLiteral("failure") ||
           normalized == QStringLiteral("error") ||
           normalized == QStringLiteral("reversed") ||
           normalized == QStringLiteral("canceled") ||
           normalized == QStringLiteral("cancelled") ||
           normalized == QStringLiteral("expired") ||
           normalized == QStringLiteral("unsubscribed") ||
           normalized == QStringLiteral("refunded");
}

bool CartModel::verifyLiqPayCallbackSignature(const QString& dataBase64, const QString& signature) const
{
    if (m_liqPayPrivateKey.trimmed().isEmpty() || dataBase64.trimmed().isEmpty() || signature.trimmed().isEmpty()) {
        return false;
    }

    const QByteArray expected = buildLiqPaySignature(m_liqPayPrivateKey, dataBase64.toUtf8());
    return QString::fromUtf8(expected).trimmed() == signature.trimmed();
}

QJsonObject CartModel::requestLiqPayStatus(const QString& providerOrderId, QString* errorMessage) const
{
    if (errorMessage) {
        errorMessage->clear();
    }

    if (providerOrderId.trimmed().isEmpty()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Порожній order_id для перевірки LiqPay");
        }
        return {};
    }

    if (m_liqPayPublicKey.trimmed().isEmpty() || m_liqPayPrivateKey.trimmed().isEmpty()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Не налаштовані ключі LiqPay");
        }
        return {};
    }

    QJsonObject payload;
    payload["action"] = "status";
    payload["version"] = "3";
    payload["public_key"] = m_liqPayPublicKey;
    payload["order_id"] = providerOrderId;

    const QByteArray payloadJson = QJsonDocument(payload).toJson(QJsonDocument::Compact);
    const QByteArray payloadBase64 = payloadJson.toBase64();
    const QByteArray signature = buildLiqPaySignature(m_liqPayPrivateKey, payloadBase64);

    QUrlQuery form;
    form.addQueryItem(QStringLiteral("data"), QString::fromUtf8(payloadBase64));
    form.addQueryItem(QStringLiteral("signature"), QString::fromUtf8(signature));
    const QByteArray body = form.query(QUrl::FullyEncoded).toUtf8();

    QNetworkRequest request(QUrl(QStringLiteral("https://www.liqpay.ua/api/request")));
    request.setHeader(QNetworkRequest::ContentTypeHeader,
                      QStringLiteral("application/x-www-form-urlencoded"));

    QNetworkAccessManager manager;
    QEventLoop loop;
    QNetworkReply* reply = manager.post(request, body);

    QTimer timeoutTimer;
    timeoutTimer.setSingleShot(true);
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    QObject::connect(&timeoutTimer, &QTimer::timeout, &loop, &QEventLoop::quit);
    timeoutTimer.start(15000);
    loop.exec();

    if (!timeoutTimer.isActive()) {
        reply->abort();
        if (errorMessage) {
            *errorMessage = QStringLiteral("Таймаут перевірки статусу LiqPay");
        }
        reply->deleteLater();
        return {};
    }
    timeoutTimer.stop();

    if (reply->error() != QNetworkReply::NoError) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Помилка запиту статусу LiqPay: %1").arg(reply->errorString());
        }
        reply->deleteLater();
        return {};
    }

    const QByteArray responseBytes = reply->readAll();
    reply->deleteLater();

    const QJsonDocument responseDoc = QJsonDocument::fromJson(responseBytes);
    if (!responseDoc.isObject()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Некоректна JSON відповідь від LiqPay status API");
        }
        return {};
    }

    const QJsonObject responseObject = responseDoc.object();
    if (responseObject.contains(QStringLiteral("err_code")) ||
        responseObject.contains(QStringLiteral("err_description"))) {
        if (errorMessage) {
            *errorMessage = responseObject.value(QStringLiteral("err_description")).toString().trimmed();
            if (errorMessage->isEmpty()) {
                *errorMessage = QStringLiteral("LiqPay повернув помилку status API");
            }
        }
        return {};
    }

    return responseObject;
}

void CartModel::clearPendingLiqPayState()
{
    m_pendingLiqPayProviderOrderId.clear();
    m_pendingLiqPayShippingAddress.clear();
    m_pendingLiqPayExpectedAmount = 0.0;
    m_pendingLiqPayCurrency = QStringLiteral("UAH");
}

QString CartModel::normalizeBase64QueryValue(QString value)
{
    value = value.trimmed();
    if (value.contains(QLatin1Char(' '))) {
        value.replace(QLatin1Char(' '), QLatin1Char('+'));
    }
    return value;
}

QByteArray CartModel::buildLiqPaySignature(const QString& privateKey, const QByteArray& dataBase64)
{
    const QByteArray signInput = privateKey.toUtf8() + dataBase64 + privateKey.toUtf8();
    return QCryptographicHash::hash(signInput, QCryptographicHash::Sha1).toBase64();
}

void CartModel::recalculateTotals()
{
    emit totalItemsChanged();
    emit totalPriceChanged();
}
