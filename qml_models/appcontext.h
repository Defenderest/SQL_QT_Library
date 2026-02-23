#ifndef APPCONTEXT_H
#define APPCONTEXT_H

#include <QObject>
#include "database.h"

class AppContext : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int currentCustomerId READ currentCustomerId WRITE setCurrentCustomerId NOTIFY currentCustomerIdChanged)
    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(bool loggedIn READ loggedIn NOTIFY loggedInChanged)
    Q_PROPERTY(bool isAdmin READ isAdmin WRITE setIsAdmin NOTIFY isAdminChanged)

public:
    explicit AppContext(QObject *parent = nullptr);

    int currentCustomerId() const;
    void setCurrentCustomerId(int customerId);

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    bool loggedIn() const;
    bool isAdmin() const;
    void setIsAdmin(bool isAdmin);

    Q_INVOKABLE void navigateTo(const QString& page);
    Q_INVOKABLE void navigateToBookDetails(int bookId);
    Q_INVOKABLE void navigateToAuthorDetails(int authorId);
    Q_INVOKABLE void showOrderDetails(int orderId);
    Q_INVOKABLE void checkout();
    Q_INVOKABLE void editProfile();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void login(int customerId);

signals:
    void currentCustomerIdChanged();
    void dbManagerChanged();
    void loggedInChanged();
    void isAdminChanged();
    void navigateToPage(const QString& page);
    void navigateToBookDetailsRequested(int bookId);
    void navigateToAuthorDetailsRequested(int authorId);
    void showOrderDetailsRequested(int orderId);
    void checkoutRequested();
    void editProfileRequested();
    void logoutRequested();
    void loginRequested();
    void errorOccurred(const QString& message);
    void infoMessage(const QString& message);

private:
    int m_currentCustomerId = -1;
    DatabaseManager* m_dbManager = nullptr;
    bool m_isAdmin = false;
};

#endif // APPCONTEXT_H
