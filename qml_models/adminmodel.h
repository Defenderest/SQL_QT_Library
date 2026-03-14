#ifndef ADMINMODEL_H
#define ADMINMODEL_H

#include <QObject>
#include <QList>
#include <QVariantList>
#include <QVariantMap>

class DatabaseManager;

class AdminModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QVariantList books READ books NOTIFY booksChanged)
    Q_PROPERTY(QVariantList comments READ comments NOTIFY commentsChanged)
    Q_PROPERTY(QVariantList orders READ orders NOTIFY ordersChanged)
    Q_PROPERTY(QVariantList users READ users NOTIFY usersChanged)

public:
    explicit AdminModel(QObject *parent = nullptr);

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    bool ready() const;
    QVariantList books() const;
    QVariantList comments() const;
    QVariantList orders() const;
    QVariantList users() const;

    Q_INVOKABLE void loadAllData();
    Q_INVOKABLE void reloadBooks();
    Q_INVOKABLE void reloadComments();
    Q_INVOKABLE void reloadOrders();
    Q_INVOKABLE void reloadUsers();

    Q_INVOKABLE bool addBook(const QString &title,
                             double price,
                             int stockQuantity,
                             const QString &genre,
                             const QString &language,
                             const QString &description,
                             const QString &coverImagePath);
    Q_INVOKABLE bool updateBook(int bookId,
                                const QString &title,
                                double price,
                                int stockQuantity,
                                const QString &genre,
                                const QString &language,
                                const QString &description,
                                const QString &coverImagePath);
    Q_INVOKABLE bool addBookStock(int bookId, int quantityToAdd);
    Q_INVOKABLE bool updateBookPrice(int bookId, double price);
    Q_INVOKABLE bool deleteBook(int bookId);

    Q_INVOKABLE bool deleteComment(int commentId);
    Q_INVOKABLE bool setUserAdminRole(int customerId, bool isAdmin);
    Q_INVOKABLE bool addOrderStatus(int orderId, const QString &status, const QString &trackingNumber);

signals:
    void dbManagerChanged();
    void readyChanged();
    void booksChanged();
    void commentsChanged();
    void ordersChanged();
    void usersChanged();
    void errorOccurred(const QString& message);
    void infoMessage(const QString& message);

private:
    QVariantList toVariantList(const QList<QVariantMap> &items) const;
    void setReady(bool ready);

    DatabaseManager* m_dbManager = nullptr;
    bool m_ready = false;
    QVariantList m_books;
    QVariantList m_comments;
    QVariantList m_orders;
    QVariantList m_users;
};

#endif // ADMINMODEL_H
