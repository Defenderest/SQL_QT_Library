#include "profilemodel.h"
#include "../core/database.h"
#include <QDebug>

ProfileModel::ProfileModel(QObject *parent)
    : QObject(parent)
{
}

DatabaseManager* ProfileModel::dbManager() const
{
    return m_dbManager;
}

void ProfileModel::setDbManager(DatabaseManager* dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
    }
}

int ProfileModel::customerId() const
{
    return m_customerId;
}

void ProfileModel::setCustomerId(int customerId)
{
    if (m_customerId != customerId) {
        m_customerId = customerId;
        emit customerIdChanged();
        // НЕ загружаем профиль автоматически - загрузим при открытии страницы
        // loadProfile();
    }
}

QString ProfileModel::firstName() const
{
    return m_profile.firstName;
}

QString ProfileModel::lastName() const
{
    return m_profile.lastName;
}

QString ProfileModel::email() const
{
    return m_profile.email;
}

QString ProfileModel::phone() const
{
    return m_profile.phone;
}

QString ProfileModel::address() const
{
    return m_profile.address;
}

QDate ProfileModel::joinDate() const
{
    return m_profile.joinDate;
}

bool ProfileModel::loyaltyProgram() const
{
    return m_profile.loyaltyProgram;
}

int ProfileModel::loyaltyPoints() const
{
    return m_profile.loyaltyPoints;
}

bool ProfileModel::loaded() const
{
    return m_profile.found;
}

void ProfileModel::loadProfile()
{
    if (!m_dbManager || m_customerId <= 0) {
        m_profile = CustomerProfileInfo();
        emit profileChanged();
        return;
    }

    m_profile = m_dbManager->getCustomerProfileInfo(m_customerId);
    emit profileChanged();
}

bool ProfileModel::updateProfile(const QString& firstName, const QString& lastName,
                                  const QString& phone, const QString& address)
{
    if (!m_dbManager || m_customerId <= 0) {
        emit errorOccurred("Not logged in");
        return false;
    }

    // TODO: Implement update in DatabaseManager
    // For now just update local data
    m_profile.firstName = firstName;
    m_profile.lastName = lastName;
    m_profile.phone = phone;
    m_profile.address = address;

    emit profileChanged();
    emit profileUpdated();
    return true;
}
