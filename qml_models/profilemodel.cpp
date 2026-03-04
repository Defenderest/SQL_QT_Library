#include "profilemodel.h"
#include "../core/database.h"
#include <QDebug>
#include <QRegularExpression>

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
        emit errorOccurred("Спочатку увійдіть у профіль");
        return false;
    }

    const QString cleanedFirstName = firstName.trimmed();
    const QString cleanedLastName = lastName.trimmed();
    const QString cleanedPhone = normalizePhone(phone);
    const QString cleanedAddress = address.trimmed();

    if (cleanedFirstName.isEmpty() || cleanedLastName.isEmpty()) {
        emit errorOccurred("Ім'я та прізвище обов'язкові");
        return false;
    }

    if (!isValidName(cleanedFirstName) || !isValidName(cleanedLastName)) {
        emit errorOccurred("Ім'я та прізвище: тільки літери, пробіл, апостроф або дефіс");
        return false;
    }

    if (cleanedPhone.isEmpty()) {
        emit errorOccurred("Телефон обов'язковий");
        return false;
    }

    if (!isValidPhone(cleanedPhone)) {
        emit errorOccurred("Невірний формат телефону. Приклад: +380XXXXXXXXX");
        return false;
    }

    const bool nameOk = m_dbManager->updateCustomerName(m_customerId, cleanedFirstName, cleanedLastName);
    const bool phoneOk = m_dbManager->updateCustomerPhone(m_customerId, cleanedPhone);
    const bool addressOk = m_dbManager->updateCustomerAddress(m_customerId, cleanedAddress);

    if (!(nameOk && phoneOk && addressOk)) {
        emit errorOccurred("Не вдалося зберегти зміни профілю");
        return false;
    }

    m_profile = m_dbManager->getCustomerProfileInfo(m_customerId);
    emit profileChanged();
    emit profileUpdated();
    return true;
}

bool ProfileModel::isValidName(const QString& value) const
{
    if (value.length() < 2 || value.length() > 40) {
        return false;
    }

    static const QRegularExpression namePattern(QStringLiteral("^[\\p{L}'\\-\\s]+$"));
    return namePattern.match(value).hasMatch();
}

bool ProfileModel::isValidPhone(const QString& value) const
{
    static const QRegularExpression phonePattern(QStringLiteral("^\\+?[0-9]{10,15}$"));
    return phonePattern.match(value).hasMatch();
}

QString ProfileModel::normalizePhone(const QString& value) const
{
    QString normalized = value.trimmed();
    normalized.remove(QRegularExpression(QStringLiteral("[\\s\\-()]")));

    if (normalized.startsWith(QStringLiteral("00"))) {
        normalized = QStringLiteral("+") + normalized.mid(2);
    }

    return normalized;
}
