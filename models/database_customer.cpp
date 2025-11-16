#include "database.h"
#include <QDebug>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>
#include <QCryptographicHash>
#include <QDate>

CustomerLoginInfo DatabaseManager::getCustomerLoginInfo(const QString &email) const
{
    CustomerLoginInfo loginInfo;
    loginInfo.found = false;
    if (!m_isConnected || !m_db.isOpen() || email.isEmpty()) {
        qWarning() << "Неможливо отримати дані для входу: немає з'єднання або email порожній.";
        return loginInfo;
    }

    const QString sql = getSqlQuery("GetCustomerLoginInfoByEmail");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetCustomerLoginInfoByEmail' не знайдено.";
        return loginInfo;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'GetCustomerLoginInfoByEmail':" << query.lastError().text();
        return loginInfo;
    }
    query.bindValue(":email", email);

    qInfo() << "Виконання SQL 'GetCustomerLoginInfoByEmail' для email:" << email;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'GetCustomerLoginInfoByEmail' для email '" << email << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        return loginInfo;
    }

    if (query.next()) {
        loginInfo.customerId = query.value("customer_id").toInt();
        loginInfo.passwordHash = query.value("password_hash").toString();
        loginInfo.found = true;
        qInfo() << "Дані для входу знайдено для email:" << email << "ID користувача:" << loginInfo.customerId;
    } else {
        qInfo() << "Дані для входу не знайдено для email:" << email;
    }

    return loginInfo;
}


CustomerProfileInfo DatabaseManager::getCustomerProfileInfo(int customerId) const
{
    CustomerProfileInfo profileInfo;
    profileInfo.found = false;
    if (!m_isConnected || !m_db.isOpen() || customerId <= 0) {
        qWarning() << "Неможливо отримати профіль: немає з'єднання або невірний customerId.";
        return profileInfo;
    }

    const QString sql = getSqlQuery("GetCustomerProfileInfoById");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetCustomerProfileInfoById' не знайдено.";
        return profileInfo;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'GetCustomerProfileInfoById':" << query.lastError().text();
        return profileInfo;
    }
    query.bindValue(":customerId", customerId);

    qInfo() << "Виконання SQL 'GetCustomerProfileInfoById' для ID користувача:" << customerId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'GetCustomerProfileInfoById' для customer ID '" << customerId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        return profileInfo;
    }

    if (query.next()) {
        profileInfo.customerId = query.value("customer_id").toInt();
        profileInfo.firstName = query.value("first_name").toString();
        profileInfo.lastName = query.value("last_name").toString();
        profileInfo.email = query.value("email").toString();
        profileInfo.phone = query.value("phone").toString();
        profileInfo.address = query.value("address").toString();
        profileInfo.joinDate = query.value("join_date").toDate();
        profileInfo.loyaltyProgram = query.value("loyalty_program").toBool();
        profileInfo.loyaltyPoints = query.value("loyalty_points").toInt();
        profileInfo.found = true;
        qInfo() << "Інформацію про профіль знайдено для ID користувача:" << customerId;
    } else {
        qInfo() << "Інформацію про профіль не знайдено для ID користувача:" << customerId;
    }

    return profileInfo;
}


bool DatabaseManager::registerCustomer(const CustomerRegistrationInfo &regInfo, int &newCustomerId)
{
    newCustomerId = -1;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо зареєструвати користувача: немає з'єднання з БД.";
        return false;
    }
    if (regInfo.email.isEmpty() || regInfo.password.isEmpty() || regInfo.firstName.isEmpty() || regInfo.lastName.isEmpty()) {
        qWarning() << "Неможливо зареєструвати користувача: не всі поля заповнені.";
        return false;
    }

    QByteArray passwordHashBytes = QCryptographicHash::hash(regInfo.password.toUtf8(), QCryptographicHash::Sha256);
    QString passwordHashHex = QString::fromUtf8(passwordHashBytes.toHex());

    const QString sql = getSqlQuery("RegisterCustomer");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'RegisterCustomer' не знайдено.";
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'RegisterCustomer':" << query.lastError().text();
        return false;
    }
    query.bindValue(":first_name", regInfo.firstName);
    query.bindValue(":last_name", regInfo.lastName);
    query.bindValue(":email", regInfo.email);
    query.bindValue(":password_hash", passwordHashHex);

    qInfo() << "Виконання SQL 'RegisterCustomer' для email:" << regInfo.email;

    QVariant insertedId;
    if (executeInsertQuery(query, QString("Реєстрація користувача %1").arg(regInfo.email), insertedId)) {
        newCustomerId = insertedId.toInt();
        qInfo() << "Користувача успішно зареєстровано. Email:" << regInfo.email << "Новий ID:" << newCustomerId;
        return true;
    } else {

        QSqlError err = query.lastError();
        if (err.isValid() && (err.text().contains("customer_email_key") || err.text().contains("duplicate key value violates unique constraint"))) {
            qWarning() << "Помилка реєстрації: Email вже існує -" << regInfo.email;
        } else if (err.isValid()) {
             qCritical() << "Помилка реєстрації для email '" << regInfo.email << "':" << err.text();
        } else {
             qCritical() << "Помилка реєстрації для email '" << regInfo.email << "' з невідомою помилкою після executeInsertQuery.";
        }
        return false;
    }
}

bool DatabaseManager::updateCustomerName(int customerId, const QString &firstName, const QString &lastName)
{
    if (!m_isConnected || !m_db.isOpen() || customerId <= 0) {
        qWarning() << "Неможливо оновити ім'я/прізвище: немає з'єднання або невірний customerId.";
        return false;
    }
    if (firstName.isEmpty() || lastName.isEmpty()) {
        qWarning() << "Неможливо оновити ім'я/прізвище: ім'я або прізвище порожні.";
        return false;
    }

    const QString sql = getSqlQuery("UpdateCustomerName");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'UpdateCustomerName' не знайдено.";
        return false;
    }
    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'UpdateCustomerName':" << query.lastError().text();
        return false;
    }
    query.bindValue(":firstName", firstName);
    query.bindValue(":lastName", lastName);
    query.bindValue(":customerId", customerId);

    qInfo() << "Виконання SQL 'UpdateCustomerName' для ID користувача:" << customerId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'UpdateCustomerName' для customer ID '" << customerId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return false;
    }

    if (query.numRowsAffected() > 0) {
        qInfo() << "Ім'я/прізвище успішно оновлено для ID користувача:" << customerId;
        return true;
    } else {
        const QString checkSql = getSqlQuery("CheckCustomerExistsById");
        if (checkSql.isEmpty()) {
            qCritical() << "SQL запит 'CheckCustomerExistsById' не знайдено.";
            return false;
        }

        QSqlQuery checkQuery(m_db);
        if (!checkQuery.prepare(checkSql)) {
             qWarning() << "Не вдалося підготувати запит 'CheckCustomerExistsById' під час перевірки оновлення імені/прізвища.";
             return false;
        }
        checkQuery.bindValue(":customerId", customerId);
        if (checkQuery.exec() && checkQuery.next()) {
             qInfo() << "Запит оновлення імені/прізвища виконано, але жодного рядка не змінено для ID користувача:" << customerId << "(Ім'я/прізвище, ймовірно, не змінилося)";
             return true;
        } else {
             qWarning() << "Запит оновлення імені/прізвища виконано, але жодного рядка не змінено для ID користувача:" << customerId << "(Користувач може не існувати)";
             return false;
        }
    }
}

bool DatabaseManager::updateCustomerAddress(int customerId, const QString &newAddress)
{
    if (!m_isConnected || !m_db.isOpen() || customerId <= 0) {
        qWarning() << "Неможливо оновити адресу: немає з'єднання або невірний customerId.";
        return false;
    }

    const QString sql = getSqlQuery("UpdateCustomerAddress");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'UpdateCustomerAddress' не знайдено.";
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'UpdateCustomerAddress':" << query.lastError().text();
        return false;
    }
    query.bindValue(":address", newAddress.isEmpty() ? QVariant(QVariant::String) : newAddress);
    query.bindValue(":customerId", customerId);

    qInfo() << "Виконання SQL 'UpdateCustomerAddress' для ID користувача:" << customerId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'UpdateCustomerAddress' для customer ID '" << customerId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return false;
    }

    if (query.numRowsAffected() > 0) {
        qInfo() << "Адресу успішно оновлено для ID користувача:" << customerId;
        return true;
    } else {
        const QString checkSql = getSqlQuery("CheckCustomerExistsById");
        if (checkSql.isEmpty()) {
            qCritical() << "SQL запит 'CheckCustomerExistsById' не знайдено.";
            return false;
        }

        QSqlQuery checkQuery(m_db);
         if (!checkQuery.prepare(checkSql)) {
             qWarning() << "Не вдалося підготувати запит 'CheckCustomerExistsById' під час перевірки оновлення адреси.";
             return false;
         }
        checkQuery.bindValue(":customerId", customerId);
         if (checkQuery.exec() && checkQuery.next()) {
            qInfo() << "Запит оновлення адреси виконано, але жодного рядка не змінено для ID користувача:" << customerId << "(Адреса, ймовірно, не змінилася)";
            return true;
        } else {
            qWarning() << "Запит оновлення адреси виконано, але жодного рядка не змінено для ID користувача:" << customerId << "(Користувач може не існувати)";
            return false;
        }
    }
}

bool DatabaseManager::addLoyaltyPoints(int customerId, int pointsToAdd)
{
    if (!m_isConnected || !m_db.isOpen() || customerId <= 0 || pointsToAdd <= 0) {
        qWarning() << "Неможливо додати бонусні бали: немає з'єднання, невірний customerId або кількість балів <= 0.";
        return false;
    }

    const QString sql = getSqlQuery("AddLoyaltyPoints");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'AddLoyaltyPoints' не знайдено.";
        return false;
    }
    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'AddLoyaltyPoints':" << query.lastError().text();
        return false;
    }
    query.bindValue(":pointsToAdd", pointsToAdd);
    query.bindValue(":customerId", customerId);

    qInfo() << "Виконання SQL 'AddLoyaltyPoints' для додавання" << pointsToAdd << "балів для ID користувача:" << customerId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'AddLoyaltyPoints' для customer ID '" << customerId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return false;
    }

    if (query.numRowsAffected() > 0) {
        qInfo() << "Бонусні бали успішно додано для ID користувача:" << customerId;
        return true;
    } else {

        const QString checkSql = getSqlQuery("CheckCustomerExistsById");
        if (checkSql.isEmpty()) {
            qCritical() << "SQL запит 'CheckCustomerExistsById' не знайдено.";
            return false;
        }
        QSqlQuery checkQuery(m_db);
        if (!checkQuery.prepare(checkSql)) {
             qWarning() << "Не вдалося підготувати запит 'CheckCustomerExistsById' під час перевірки оновлення бонусних балів.";
             return false;
        }
        checkQuery.bindValue(":customerId", customerId);
        if (checkQuery.exec() && checkQuery.next()) {
            qWarning() << "Запит оновлення бонусних балів виконано, але жодного рядка не змінено для ID користувача:" << customerId << "(Не повинно статися, якщо pointsToAdd не було 0)";

            return false;
        } else {
            qWarning() << "Запит оновлення бонусних балів виконано, але жодного рядка не змінено для ID користувача:" << customerId << "(Користувач може не існувати)";
            return false;
        }
    }
}


bool DatabaseManager::updateCustomerPhone(int customerId, const QString &newPhone)
{
    if (!m_isConnected || !m_db.isOpen() || customerId <= 0) {
        qWarning() << "Неможливо оновити телефон: немає з'єднання або невірний customerId.";
        return false;
    }

    const QString sql = getSqlQuery("UpdateCustomerPhone");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'UpdateCustomerPhone' не знайдено.";
        return false;
    }
    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'UpdateCustomerPhone':" << query.lastError().text();
        return false;
    }
    query.bindValue(":phone", newPhone.isEmpty() ? QVariant(QVariant::String) : newPhone);
    query.bindValue(":customerId", customerId);

    qInfo() << "Виконання SQL 'UpdateCustomerPhone' для ID користувача:" << customerId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'UpdateCustomerPhone' для customer ID '" << customerId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return false;
    }

    if (query.numRowsAffected() > 0) {
        qInfo() << "Номер телефону успішно оновлено для ID користувача:" << customerId;
        return true;
    } else {

        const QString checkSql = getSqlQuery("CheckCustomerExistsById");
        if (checkSql.isEmpty()) {
            qCritical() << "SQL запит 'CheckCustomerExistsById' не знайдено.";
            return false;
        }
        QSqlQuery checkQuery(m_db);
         if (!checkQuery.prepare(checkSql)) {
             qWarning() << "Не вдалося підготувати запит 'CheckCustomerExistsById' під час перевірки оновлення телефону.";
             return false;
         }
        checkQuery.bindValue(":customerId", customerId);
         if (checkQuery.exec() && checkQuery.next()) {
            qInfo() << "Запит оновлення телефону виконано, але жодного рядка не змінено для ID користувача:" << customerId << "(Телефон, ймовірно, не змінився)";
            return true;
        } else {
            qWarning() << "Запит оновлення телефону виконано, але жодного рядка не змінено для ID користувача:" << customerId << "(Користувач може не існувати)";
            return false;
        }
    }
}
