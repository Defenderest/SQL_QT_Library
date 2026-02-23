#include "appcontext.h"
#include <QDebug>

AppContext::AppContext(QObject *parent)
    : QObject(parent)
{
}

int AppContext::currentCustomerId() const
{
    return m_currentCustomerId;
}

void AppContext::setCurrentCustomerId(int customerId)
{
    if (m_currentCustomerId != customerId) {
        m_currentCustomerId = customerId;
        emit currentCustomerIdChanged();
        emit loggedInChanged();
    }
}

DatabaseManager* AppContext::dbManager() const
{
    return m_dbManager;
}

void AppContext::setDbManager(DatabaseManager* dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
    }
}

bool AppContext::loggedIn() const
{
    return m_currentCustomerId > 0;
}

bool AppContext::isAdmin() const
{
    return m_isAdmin;
}

void AppContext::setIsAdmin(bool isAdmin)
{
    if (m_isAdmin != isAdmin) {
        m_isAdmin = isAdmin;
        emit isAdminChanged();
    }
}

void AppContext::navigateTo(const QString& page)
{
    emit navigateToPage(page);
}

void AppContext::navigateToBookDetails(int bookId)
{
    emit navigateToBookDetailsRequested(bookId);
}

void AppContext::navigateToAuthorDetails(int authorId)
{
    emit navigateToAuthorDetailsRequested(authorId);
}

void AppContext::showOrderDetails(int orderId)
{
    emit showOrderDetailsRequested(orderId);
}

void AppContext::checkout()
{
    emit checkoutRequested();
}

void AppContext::editProfile()
{
    emit editProfileRequested();
}

void AppContext::logout()
{
    m_currentCustomerId = -1;
    m_isAdmin = false;
    emit currentCustomerIdChanged();
    emit loggedInChanged();
    emit isAdminChanged();
    emit logoutRequested();
}

void AppContext::login(int customerId)
{
    setCurrentCustomerId(customerId);
    emit loginRequested();
}
