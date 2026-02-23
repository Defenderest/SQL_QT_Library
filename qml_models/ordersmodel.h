#ifndef ORDERSMODEL_H
#define ORDERSMODEL_H

#include <QAbstractListModel>
#include <QList>
#include "../models/datatypes.h"

class DatabaseManager;

class OrdersModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(int customerId READ customerId WRITE setCustomerId NOTIFY customerIdChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum OrderRoles {
        OrderIdRole = Qt::UserRole + 1,
        OrderDateRole,
        TotalAmountRole,
        StatusRole,
        ShippingAddressRole,
        PaymentMethodRole,
        ItemCountRole
    };
    Q_ENUM(OrderRoles)

    explicit OrdersModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    int customerId() const;
    void setCustomerId(int customerId);

    int count() const;

    Q_INVOKABLE void loadOrders();
    Q_INVOKABLE QVariantMap getOrderDetails(int orderId);

signals:
    void dbManagerChanged();
    void customerIdChanged();
    void countChanged();
    void errorOccurred(const QString& message);

private:
    DatabaseManager* m_dbManager = nullptr;
    int m_customerId = -1;
    QList<OrderDisplayInfo> m_orders;
};

#endif // ORDERSMODEL_H
