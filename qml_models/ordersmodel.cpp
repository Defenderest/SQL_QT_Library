#include "ordersmodel.h"
#include "../core/database.h"
#include <QDebug>

OrdersModel::OrdersModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int OrdersModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_orders.count();
}

QVariant OrdersModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_orders.count())
        return QVariant();

    const OrderDisplayInfo &order = m_orders.at(index.row());

    switch (role) {
    case OrderIdRole:
        return order.orderId;
    case OrderDateRole:
        return order.orderDate.toString("dd.MM.yyyy");
    case TotalAmountRole:
        return order.totalAmount;
    case StatusRole:
        return order.status;
    case ShippingAddressRole:
        return order.shippingAddress;
    case PaymentMethodRole:
        return order.paymentMethod;
    case ItemCountRole:
        return order.items.count();
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> OrdersModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[OrderIdRole] = "orderId";
    roles[OrderDateRole] = "orderDate";
    roles[TotalAmountRole] = "totalAmount";
    roles[StatusRole] = "status";
    roles[ShippingAddressRole] = "shippingAddress";
    roles[PaymentMethodRole] = "paymentMethod";
    roles[ItemCountRole] = "itemCount";
    return roles;
}

DatabaseManager* OrdersModel::dbManager() const
{
    return m_dbManager;
}

void OrdersModel::setDbManager(DatabaseManager* dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
    }
}

int OrdersModel::customerId() const
{
    return m_customerId;
}

void OrdersModel::setCustomerId(int customerId)
{
    if (m_customerId != customerId) {
        m_customerId = customerId;
        emit customerIdChanged();
        // НЕ загружаем заказы автоматически - загрузим при открытии страницы
        // loadOrders();
    }
}

int OrdersModel::count() const
{
    return m_orders.count();
}

void OrdersModel::loadOrders()
{
    if (!m_dbManager || m_customerId <= 0) {
        beginResetModel();
        m_orders.clear();
        endResetModel();
        emit countChanged();
        return;
    }

    beginResetModel();
    m_orders = m_dbManager->getCustomerOrdersForDisplay(m_customerId);
    endResetModel();
    emit countChanged();
}

QVariantMap OrdersModel::getOrderDetails(int orderId)
{
    QVariantMap details;

    for (const auto& order : m_orders) {
        if (order.orderId == orderId) {
            details["orderId"] = order.orderId;
            details["orderDate"] = order.orderDate.toString("dd.MM.yyyy HH:mm");
            details["orderDateIso"] = order.orderDate.toString(Qt::ISODate);
            details["orderDateMs"] = order.orderDate.isValid() ? order.orderDate.toMSecsSinceEpoch() : 0;
            details["totalAmount"] = order.totalAmount;
            details["status"] = order.status;
            details["shippingAddress"] = order.shippingAddress;
            details["paymentMethod"] = order.paymentMethod;

            QVariantList items;
            for (const auto& item : order.items) {
                QVariantMap itemMap;
                itemMap["bookTitle"] = item.bookTitle;
                itemMap["quantity"] = item.quantity;
                itemMap["pricePerUnit"] = item.pricePerUnit;
                items.append(itemMap);
            }
            details["items"] = items;

            QVariantList statuses;
            for (const auto& status : order.statuses) {
                QVariantMap statusMap;
                statusMap["status"] = status.status;
                statusMap["statusDate"] = status.statusDate.toString("dd.MM.yyyy HH:mm");
                statusMap["statusDateIso"] = status.statusDate.toString(Qt::ISODate);
                statusMap["statusDateMs"] = status.statusDate.isValid() ? status.statusDate.toMSecsSinceEpoch() : 0;
                statusMap["trackingNumber"] = status.trackingNumber;
                statuses.append(statusMap);
            }
            details["statuses"] = statuses;

            return details;
        }
    }

    return details;
}
