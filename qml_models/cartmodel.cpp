#include "cartmodel.h"
#include "../core/database.h"
#include <QDebug>

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

void CartModel::recalculateTotals()
{
    emit totalItemsChanged();
    emit totalPriceChanged();
}
