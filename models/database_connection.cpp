#include "database.h"
#include <QDebug>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>
#include <QVector>
#include <QDate>
#include <QDateTime>
#include <QSqlRecord>
#include <QMap>
#include <QFile>
#include <QTextStream>
#include <QDir>

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent), m_isConnected(false)
{
    if (!loadSqlQueries()) {
        qCritical() << "ФАТАЛЬНА ПОМИЛКА: Не вдалося завантажити SQL запити. Операції з базою даних, ймовірно, завершаться невдачею.";
    }

    if (!QSqlDatabase::isDriverAvailable("QPSQL")) {
        qCritical() << "Помилка: Драйвер QPSQL для PostgreSQL недоступний!";
        qCritical() << "Доступні драйвери:" << QSqlDatabase::drivers();
    }
}

DatabaseManager::~DatabaseManager()
{
    closeConnection();
}

bool DatabaseManager::connectToDatabase(const QString &host,
                                        int port,
                                        const QString &dbName,
                                        const QString &user,
                                        const QString &password)
{
    closeConnection();
    const QString connectionName = QString("db_connection_%1").arg(QDateTime::currentMSecsSinceEpoch());
    m_db = QSqlDatabase::addDatabase("QPSQL", connectionName);
    m_db.setHostName(host);
    m_db.setPort(port);
    m_db.setDatabaseName(dbName);
    m_db.setUserName(user);
    m_db.setPassword(password);

    if (!m_db.open()) {
        qCritical() << "Не вдалося підключитися до бази даних:";
        qCritical() << m_db.lastError().text();
        m_isConnected = false;
        QSqlDatabase::removeDatabase(connectionName);
        return false;
    }

    qDebug() << "Успішно підключено до бази даних" << dbName << "на" << host << ":" << port << "З'єднання:" << connectionName;
    m_isConnected = true;
    return true;
}

bool DatabaseManager::createSchemaTables()
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо створити таблиці: немає активного з'єднання з БД.";
        return false;
    }

    if (!m_db.transaction()) {
        qCritical() << "Не вдалося розпочати транзакцію:" << m_db.lastError().text();
        return false;
    }
    qInfo() << "Транзакцію розпочато для створення схеми...";

    QSqlQuery query(m_db);
    bool success = true;

    // Drop triggers and functions first
    success &= executeQuery(query, getSqlQuery("DropAwardLoyaltyPointsTriggerDefinition"), "Видалення тригера trg_award_loyalty_points_on_order_completion");
    if(success) success &= executeQuery(query, getSqlQuery("DropAwardLoyaltyPointsTriggerFunction"), "Видалення функції award_loyalty_points_on_order_completion");
    if(success) success &= executeQuery(query, getSqlQuery("DropCalculateAverageRatingFunction"), "Видалення функції calculate_average_book_rating");


    // Drop tables
    if(success) success &= executeQuery(query, getSqlQuery("DropOrderStatusTable"), "Видалення order_status");
    if(success) success &= executeQuery(query, getSqlQuery("DropOrderItemTable"),   "Видалення order_item");
    if(success) success &= executeQuery(query, getSqlQuery("DropCommentTable"),     "Видалення comment");
    if(success) success &= executeQuery(query, getSqlQuery("DropBookAuthorTable"),  "Видалення book_author");
    if(success) success &= executeQuery(query, getSqlQuery("DropOrderTable"),       "Видалення \"order\"");
    if(success) success &= executeQuery(query, getSqlQuery("DropCartItemTable"),    "Видалення cart_item");
    if(success) success &= executeQuery(query, getSqlQuery("DropBookTable"),        "Видалення book");
    if(success) success &= executeQuery(query, getSqlQuery("DropAuthorTable"),      "Видалення author");
    if(success) success &= executeQuery(query, getSqlQuery("DropPublisherTable"),   "Видалення publisher");
    if(success) success &= executeQuery(query, getSqlQuery("DropCustomerTable"),    "Видалення customer");

    // Create tables
    if(success) success &= executeQuery(query, getSqlQuery("CreateCustomerTable"), "Створення customer");
    if(success) success &= executeQuery(query, getSqlQuery("CreatePublisherTable"), "Створення publisher");
    if(success) success &= executeQuery(query, getSqlQuery("CreateAuthorTable"), "Створення author");
    if(success) success &= executeQuery(query, getSqlQuery("CreateBookTable"), "Створення book");
    if(success) success &= executeQuery(query, getSqlQuery("CreateOrderTable"), "Створення \"order\"");
    if(success) success &= executeQuery(query, getSqlQuery("CreateBookAuthorTable"), "Створення book_author");
    if(success) success &= executeQuery(query, getSqlQuery("CreateOrderItemTable"), "Створення order_item");
    if(success) success &= executeQuery(query, getSqlQuery("CreateOrderStatusTable"), "Створення order_status");
    if(success) success &= executeQuery(query, getSqlQuery("CreateCommentTable"), "Створення comment");
    if(success) success &= executeQuery(query, getSqlQuery("CreateCartItemTable"), "Створення cart_item");

    // Create functions and triggers
    if(success) success &= executeQuery(query, getSqlQuery("CreateCalculateAverageRatingFunction"), "Створення функції calculate_average_book_rating");
    if(success) success &= executeQuery(query, getSqlQuery("CreateAwardLoyaltyPointsTrigger"), "Створення функції award_loyalty_points_on_order_completion");
    if(success) success &= executeQuery(query, getSqlQuery("CreateAwardLoyaltyPointsTriggerDefinition"), "Створення тригера trg_award_loyalty_points_on_order_completion");


    if (success) {
        if (m_db.commit()) {
            qInfo() << "Транзакцію створення схеми успішно завершено.";
            return true;
        } else {
            qCritical() << "Помилка при коміті транзакції створення схеми:" << m_db.lastError().text();
            m_db.rollback();
            return false;
        }
    } else {
        qWarning() << "Сталася помилка при створенні схеми. Відкат транзакції...";
        if (!m_db.rollback()) {
            qCritical() << "Помилка при відкаті транзакції створення схеми:" << m_db.lastError().text();
        } else {
            qInfo() << "Транзакцію створення схеми успішно скасовано.";
        }
        return false;
    }
}

bool DatabaseManager::executeQuery(QSqlQuery &query, const QString &sql, const QString &description)
{
    qInfo().noquote() << QString("Виконання SQL (%1): %2").arg(description, sql.left(100).replace("\n", " ").simplified().append("..."));
    if (!query.exec(sql)) {
        qCritical().noquote() << QString("Помилка при виконанні SQL (%1):").arg(description);
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << sql;
        return false;
    }
    return true;
}

bool DatabaseManager::executeInsertQuery(QSqlQuery &query, const QString &description, QVariant &insertedId)
{
    qInfo().noquote() << QString("Виконання підготовленого INSERT (%1)...").arg(description);

    if (!query.exec()) {
        qCritical().noquote() << QString("Помилка виконання підготовленого INSERT (%1):").arg(description);
        qCritical() << query.lastError().text();
        qCritical() << "Підготовлений запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return false;
    }

    if (query.next()) {
        insertedId = query.value(0);
        if (!insertedId.isValid() || insertedId.isNull()) {
            qWarning() << "Попередження: Не вдалося отримати ID після INSERT для" << description;
        }
        return true;
    } else {
        qWarning() << "Попередження: Запит INSERT виконано, але RETURNING не повернув рядка для" << description;
        return true;
    }
}

bool DatabaseManager::isConnected() const
{
    return m_isConnected;
}

QSqlDatabase& DatabaseManager::database()
{
    if (!m_db.isValid()) {
         qWarning() << "DatabaseManager::database(): Спроба доступу до недійсного об'єкту QSqlDatabase.";
    } else if (m_isConnected && !m_db.isOpen()) {
         qWarning() << "DatabaseManager::database(): З'єднання позначено як активне, але об'єкт QSqlDatabase закритий.";
    }
    return m_db;
}

QSqlError DatabaseManager::lastError() const
{
    if (m_db.isValid()) {
        return m_db.lastError();
    } else {
        qWarning() << "DatabaseManager::lastError(): Спроба отримати помилку для недійсного об'єкту QSqlDatabase.";
        return QSqlError();
    }
}

void DatabaseManager::closeConnection()
{
    if (m_db.isOpen()) {
        QString connectionName = m_db.connectionName();
        m_db.close();
        qInfo() << "З'єднання з базою даних" << connectionName << "закрито.";
    }
    if (QSqlDatabase::contains(m_db.connectionName())) {
         QSqlDatabase::removeDatabase(m_db.connectionName());
         qInfo() << "З'єднання" << m_db.connectionName() << "видалено з пулу.";
    }
    m_isConnected = false;
}

bool DatabaseManager::printAllData() const
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо вивести дані: немає активного з'єднання з БД.";
        return false;
    }

    qInfo() << "\n===============================================";
    qInfo() << "       ВИВЕДЕННЯ ДАНИХ З УСІХ ТАБЛИЦЬ        ";
    qInfo() << "===============================================";

    const QStringList tables = {"customer", "publisher", "author", "book", "\"order\"",
                                "book_author", "order_item", "order_status", "comment", "cart_item"};

    bool overallSuccess = true;

    for (const QString &tableName : tables) {
        qInfo().noquote() << "\n--- Таблиця:" << tableName << "---";

        QSqlQuery query(m_db);
        QString sql = QString("SELECT * FROM %1;").arg(tableName);

        if (!query.exec(sql)) {
            qCritical().noquote() << QString("Помилка при отриманні даних з таблиці '%1':").arg(tableName);
            qCritical() << query.lastError().text();
            overallSuccess = false;
            continue;
        }

        QSqlRecord record = query.record();
        if (record.isEmpty() && query.size() == 0) {
            qInfo().noquote() << "(Таблиця порожня або не містить колонок)";
            continue;
        }

        QString headerLine;
        for (int i = 0; i < record.count(); ++i) {
            headerLine += record.fieldName(i) + "\t";
        }
        qInfo().noquote() << headerLine.trimmed();

        QString separatorLine;
        for (int i = 0; i < record.count(); ++i) {
            separatorLine += QString(record.fieldName(i).length(), '-') + "\t";
        }
        qInfo().noquote() << separatorLine.trimmed();


        int rowCount = 0;
        while (query.next()) {
            QString dataLine;
            for (int i = 0; i < record.count(); ++i) {
                QVariant value = query.value(i);
                dataLine += (value.isNull() ? "(NULL)" : value.toString()) + "\t";
            }
            qInfo().noquote() << dataLine.trimmed();
            rowCount++;
        }

        if (rowCount == 0 && !record.isEmpty()) {
            qInfo().noquote() << "(Немає даних)";
        } else {
            qInfo().noquote() << QString("-> Всього рядків: %1").arg(rowCount);
        }
    }

    qInfo() << "\n===============================================";
    qInfo() << "       Завершення виведення даних           ";
    qInfo() << "===============================================";


    return overallSuccess;
}

bool DatabaseManager::loadSqlQueries(const QString& directory)
{
    m_sqlQueries.clear();
    QDir sqlDir(directory);
    if (!sqlDir.exists()) {
        qCritical() << "Каталог SQL не знайдено:" << sqlDir.absolutePath();
        return false;
    }

    qInfo() << "Завантаження SQL запитів з каталогу:" << sqlDir.absolutePath();
    QStringList sqlFiles = sqlDir.entryList(QStringList() << "*.sql", QDir::Files);
    bool allParsed = true;

    for (const QString& fileName : sqlFiles) {
        QString filePath = sqlDir.absoluteFilePath(fileName);
        if (!parseSqlFile(filePath)) {
            qWarning() << "Не вдалося розібрати SQL файл:" << filePath;
            allParsed = false;
        }
    }

    qInfo() << QString("Завантажено %1 SQL запитів з %2 файлів.").arg(m_sqlQueries.count()).arg(sqlFiles.count());
    if (!allParsed) {
         qWarning() << "Деякі SQL файли не вдалося розібрати коректно.";
    }
    return allParsed;
}

bool DatabaseManager::parseSqlFile(const QString& filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qCritical() << "Не вдається відкрити SQL файл для читання:" << filePath << file.errorString();
        return false;
    }

    QTextStream in(&file);
    QString currentQueryName;
    QString currentQuerySql;
    int queryCount = 0;

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();

        if (line.startsWith("-- name:")) {
            if (!currentQueryName.isEmpty() && !currentQuerySql.isEmpty()) {
                m_sqlQueries.insert(currentQueryName, currentQuerySql.trimmed());
                queryCount++;
            }

            currentQueryName = line.mid(8).trimmed();
            currentQuerySql.clear();

            if (currentQueryName.isEmpty()) {
                qWarning() << "Знайдено порожнє ім'я запиту після '-- name:' у файлі:" << filePath << "Рядок:" << line;
            }
        } else if (!currentQueryName.isEmpty() && !line.startsWith("--") && !line.isEmpty()) {
            currentQuerySql += line + "\n";
        }
    }

    if (!currentQueryName.isEmpty() && !currentQuerySql.isEmpty()) {
        m_sqlQueries.insert(currentQueryName, currentQuerySql.trimmed());
        queryCount++;
    }

    file.close();
    qInfo() << QString("Розібрано %1 запитів з файлу:").arg(queryCount) << filePath;
    return true;
}

QString DatabaseManager::getSqlQuery(const QString& queryName) const
{
    if (!m_sqlQueries.contains(queryName)) {
        qCritical() << "SQL запит не знайдено:" << queryName;
        return QString();
    }
    return m_sqlQueries.value(queryName);
}
