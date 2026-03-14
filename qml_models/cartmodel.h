#ifndef CARTMODEL_H
#define CARTMODEL_H

#include <QAbstractListModel>
#include <QByteArray>
#include <QJsonObject>
#include <QMap>
#include "../models/datatypes.h"

class DatabaseManager;

// Forward declaration - CartItem struct is in datatypes.h

class CartModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(int customerId READ customerId WRITE setCustomerId NOTIFY customerIdChanged)
    Q_PROPERTY(int totalItems READ totalItems NOTIFY totalItemsChanged)
    Q_PROPERTY(double totalPrice READ totalPrice NOTIFY totalPriceChanged)
    Q_PROPERTY(QString liqPayPublicKey READ liqPayPublicKey WRITE setLiqPayPublicKey NOTIFY liqPayConfigChanged)
    Q_PROPERTY(QString liqPayPrivateKey READ liqPayPrivateKey WRITE setLiqPayPrivateKey NOTIFY liqPayConfigChanged)

public:
    enum CartRoles {
        BookIdRole = Qt::UserRole + 1,
        TitleRole,
        AuthorRole,
        PriceRole,
        QuantityRole,
        CoverImagePathRole,
        SubtotalRole
    };

    explicit CartModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    int customerId() const;
    void setCustomerId(int customerId);
    QString liqPayPublicKey() const;
    void setLiqPayPublicKey(const QString& publicKey);
    QString liqPayPrivateKey() const;
    void setLiqPayPrivateKey(const QString& privateKey);

    int totalItems() const;
    double totalPrice() const;

    Q_INVOKABLE void loadCart();
    Q_INVOKABLE void addItem(int bookId);
    Q_INVOKABLE void removeItem(int bookId);
    Q_INVOKABLE void increaseQuantity(int bookId);
    Q_INVOKABLE void decreaseQuantity(int bookId);
    Q_INVOKABLE void clearCart();
    Q_INVOKABLE bool checkout(const QString& shippingAddress,
                             const QString& paymentMethod,
                             const QString& reservationProviderOrderId = QString());
    Q_INVOKABLE void startLiqPayCheckout(const QString& shippingAddress);
    Q_INVOKABLE void verifyPendingLiqPayPayment(const QString& callbackUrl = QString());
    Q_INVOKABLE void cancelPendingLiqPayCheckout();

signals:
    void dbManagerChanged();
    void customerIdChanged();
    void totalItemsChanged();
    void totalPriceChanged();
    void liqPayConfigChanged();
    void errorOccurred(const QString& message);
    void itemAdded(const QString& bookTitle);
    void checkoutSucceeded(int orderId);
    void checkoutFailed(const QString& message);
    void liqPayCheckoutOpened(const QString& checkoutUrl);
    void liqPayCheckoutFailed(const QString& message);

private:
    DatabaseManager* m_dbManager = nullptr;
    int m_customerId = -1;
    QList<CartItem> m_items;
    QString m_liqPayPublicKey;
    QString m_liqPayPrivateKey;
    QString m_pendingLiqPayProviderOrderId;
    QString m_pendingLiqPayShippingAddress;
    double m_pendingLiqPayExpectedAmount = 0.0;
    QString m_pendingLiqPayCurrency = "UAH";
    int m_lastCheckoutOrderId = -1;

    void recalculateTotals();
    QString buildLiqPayCheckoutUrl(const QString& shippingAddress,
                                  const QString& orderId,
                                  QString* outDataBase64 = nullptr,
                                  QString* outSignature = nullptr) const;
    bool isSuccessfulLiqPayStatus(const QString& status) const;
    bool isTerminalFailedLiqPayStatus(const QString& status) const;
    bool verifyLiqPayCallbackSignature(const QString& dataBase64, const QString& signature) const;
    QJsonObject requestLiqPayStatus(const QString& providerOrderId, QString* errorMessage) const;
    void clearPendingLiqPayState();
    static QString normalizeBase64QueryValue(QString value);
    static QByteArray buildLiqPaySignature(const QString& privateKey, const QByteArray& dataBase64);
};

#endif // CARTMODEL_H
