#include "cartmodel.h"
#include "../core/database.h"
#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>

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
    if (!m_dbManager || m_customerId <= 0) {
        emit errorOccurred("Database manager not set");
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
    if (!m_dbManager || m_customerId <= 0) {
        emit errorOccurred("Database manager not set");
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
    if (!m_dbManager || m_customerId <= 0) {
        emit errorOccurred("Database manager not set");
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
    if (!m_dbManager || m_customerId <= 0) {
        emit errorOccurred("Database manager not set");
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

bool CartModel::checkout(const QString& shippingAddress, const QString& paymentMethod)
{
    if (!m_dbManager || m_customerId <= 0) {
        const QString message = "Database manager not set";
        emit errorOccurred(message);
        emit checkoutFailed(message);
        return false;
    }

    if (shippingAddress.trimmed().isEmpty()) {
        const QString message = "Shipping address is required";
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

    int newOrderId = -1;
    const double total = m_dbManager->createOrder(
        m_customerId,
        itemsToOrder,
        shippingAddress.trimmed(),
        paymentMethod.trimmed(),
        newOrderId
    );

    if (total < 0.0 || newOrderId <= 0) {
        const QString message = "Failed to create order";
        emit errorOccurred(message);
        emit checkoutFailed(message);
        return false;
    }

    loadCart();
    emit checkoutSucceeded(newOrderId);
    return true;
}

void CartModel::startLiqPayCheckout(const QString& shippingAddress)
{
    if (m_customerId <= 0) {
        emit liqPayCheckoutFailed("Користувач не авторизований");
        return;
    }

    const QString cleanAddress = shippingAddress.trimmed();
    if (cleanAddress.isEmpty()) {
        emit liqPayCheckoutFailed("Вкажіть адресу доставки");
        return;
    }

    if (m_items.isEmpty()) {
        emit liqPayCheckoutFailed("Кошик порожній");
        return;
    }

    if (m_liqPayPublicKey.trimmed().isEmpty() || m_liqPayPrivateKey.trimmed().isEmpty()) {
        emit liqPayCheckoutFailed("Не знайдено ключі LiqPay. Потрібні змінні: LIQPAY_PUBLIC_KEY/LIQPAY_PRIVATE_KEY (або LIQPAY_SANDBOX_PUBLIC_KEY/LIQPAY_SANDBOX_PRIVATE_KEY, або PUBLIC_KEY/PRIVATE_KEY)");
        return;
    }

    const QString orderId = QString("COURSE_%1_%2")
        .arg(m_customerId)
        .arg(QDateTime::currentMSecsSinceEpoch());
    const QString checkoutUrl = buildLiqPayCheckoutUrl(cleanAddress, orderId);
    if (checkoutUrl.isEmpty()) {
        emit liqPayCheckoutFailed("Не вдалося сформувати посилання LiqPay");
        return;
    }

    emit liqPayCheckoutOpened(checkoutUrl);
}

QString CartModel::buildLiqPayCheckoutUrl(const QString& shippingAddress, const QString& orderId) const
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

    const QByteArray jsonPayload = QJsonDocument(payload).toJson(QJsonDocument::Compact);
    const QByteArray dataBase64 = jsonPayload.toBase64();
    const QByteArray signature = buildLiqPaySignature(m_liqPayPrivateKey, dataBase64);

    QString url = "https://www.liqpay.ua/api/3/checkout";
    url += "?data=" + QString::fromUtf8(QUrl::toPercentEncoding(QString::fromUtf8(dataBase64)));
    url += "&signature=" + QString::fromUtf8(QUrl::toPercentEncoding(QString::fromUtf8(signature)));
    return url;
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
