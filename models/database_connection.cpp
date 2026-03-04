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

#include <QCoreApplication>

#include "testdata.h"

bool DatabaseManager::checkAndInitDatabase()
{
    if (!m_isConnected) return false;

    const auto readEnvBool = [](const char* name, bool fallback = false) {
        if (!qEnvironmentVariableIsSet(name)) {
            return fallback;
        }

        const QString value = qEnvironmentVariable(name).trimmed().toLower();
        return value == QStringLiteral("1") ||
               value == QStringLiteral("true") ||
               value == QStringLiteral("yes") ||
               value == QStringLiteral("on");
    };

    const bool allowSeedTestData = readEnvBool("LIBRARY_SEED_TEST_DATA", false);
    const bool allowAutoAssignAdmin = readEnvBool("LIBRARY_AUTO_ASSIGN_ADMIN", false);

    QStringList tables = m_db.tables();
    // Простейшая проверка: если нет таблицы customer, считаем что БД пустая
    if (!tables.contains("customer", Qt::CaseInsensitive)) {
        qInfo() << "Database tables not found. Creating schema...";
        if (createSchemaTables()) {
            if (allowSeedTestData) {
                qInfo() << "Schema created. Populating test data...";
                if (!populateTestData(this, 30)) {
                    qWarning() << "Test data population failed during init.";
                }
            } else {
                qInfo() << "Schema created. Test data seeding is disabled (set LIBRARY_SEED_TEST_DATA=1 to enable).";
            }
            tables = m_db.tables();
        }
        else {
            return false;
        }
    }

    // Lightweight migration for existing installations.
    QSqlQuery migrationQuery(m_db);
    if (!migrationQuery.exec("ALTER TABLE customer ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;")) {
        qWarning() << "Failed to ensure customer.is_admin column:" << migrationQuery.lastError().text();
    }

    if (!migrationQuery.exec("ALTER TABLE customer ALTER COLUMN password_hash TYPE TEXT;")) {
        qWarning() << "Failed to ensure customer.password_hash type:" << migrationQuery.lastError().text();
    }

    int adminCount = 0;
    if (migrationQuery.exec("SELECT COUNT(*) FROM customer WHERE COALESCE(is_admin, FALSE) = TRUE;") && migrationQuery.next()) {
        adminCount = migrationQuery.value(0).toInt();
    }

    if (allowAutoAssignAdmin && adminCount == 0) {
        if (!migrationQuery.exec("UPDATE customer SET is_admin = TRUE WHERE customer_id = (SELECT customer_id FROM customer ORDER BY customer_id ASC LIMIT 1);")) {
            qWarning() << "Failed to assign default admin:" << migrationQuery.lastError().text();
        } else if (migrationQuery.numRowsAffected() > 0) {
            qInfo() << "Assigned admin role to the first customer account.";
        }
    } else if (!allowAutoAssignAdmin && adminCount == 0) {
        qInfo() << "No admin accounts found. Auto-assignment disabled (set LIBRARY_AUTO_ASSIGN_ADMIN=1 to enable).";
    }

    const QStringList paymentMigrations = {
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS payment_transaction ("
            "payment_transaction_id SERIAL PRIMARY KEY, "
            "provider VARCHAR(32) NOT NULL, "
            "provider_order_id VARCHAR(128) NOT NULL UNIQUE, "
            "customer_id INTEGER NOT NULL, "
            "order_id INTEGER, "
            "amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0), "
            "currency VARCHAR(10) NOT NULL, "
            "status VARCHAR(40) NOT NULL, "
            "checkout_url TEXT, "
            "request_data_base64 TEXT, "
            "request_signature VARCHAR(255), "
            "response_data_base64 TEXT, "
            "response_signature VARCHAR(255), "
            "provider_payment_id VARCHAR(128), "
            "created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, "
            "updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, "
            "verified_at TIMESTAMPTZ, "
            "CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE, "
            "CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES \"order\"(order_id) ON DELETE SET NULL"
            ");"
        ),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS payment_status_history ("
            "payment_status_history_id SERIAL PRIMARY KEY, "
            "payment_transaction_id INTEGER NOT NULL, "
            "status VARCHAR(40) NOT NULL, "
            "status_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, "
            "details TEXT, "
            "CONSTRAINT fk_payment_transaction FOREIGN KEY (payment_transaction_id) REFERENCES payment_transaction(payment_transaction_id) ON DELETE CASCADE"
            ");"
        )
    };

    for (const QString& migrationSql : paymentMigrations) {
        if (!migrationQuery.exec(migrationSql)) {
            qWarning() << "Failed to ensure payment table:" << migrationQuery.lastError().text();
            qWarning() << "SQL:" << migrationSql;
        }
    }

    const QStringList performanceIndexes = {
        "CREATE INDEX IF NOT EXISTS idx_order_customer_date ON \"order\" (customer_id, order_date DESC);",
        "CREATE INDEX IF NOT EXISTS idx_order_status_order_date ON order_status (order_id, status_date DESC);",
        "CREATE INDEX IF NOT EXISTS idx_order_item_order ON order_item (order_id);",
        "CREATE INDEX IF NOT EXISTS idx_comment_book_date ON comment (book_id, comment_date DESC);",
        "CREATE INDEX IF NOT EXISTS idx_book_genre_language ON book (genre, language);",
        "CREATE INDEX IF NOT EXISTS idx_book_title_lower ON book (LOWER(title));",
        "CREATE INDEX IF NOT EXISTS idx_author_full_name_lower ON author (LOWER(first_name || ' ' || last_name));",
        "CREATE INDEX IF NOT EXISTS idx_payment_transaction_provider_order ON payment_transaction (provider_order_id);",
        "CREATE INDEX IF NOT EXISTS idx_payment_status_history_tx_date ON payment_status_history (payment_transaction_id, status_date DESC);"
    };

    for (const QString& indexSql : performanceIndexes) {
        if (!migrationQuery.exec(indexSql)) {
            qWarning() << "Failed to ensure performance index:" << migrationQuery.lastError().text();
            qWarning() << "SQL:" << indexSql;
        }
    }

    return true;
}

bool DatabaseManager::resetDatabase()
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо скинути БД: немає активного з'єднання.";
        return false;
    }

    qInfo() << "Скидання бази даних...";

    QSqlQuery query(m_db);

    // Видаляємо всі таблиці у правильному порядку (враховуючи зовнішні ключі)
    QStringList dropStatements = {
        "DROP TABLE IF EXISTS payment_status_history CASCADE",
        "DROP TABLE IF EXISTS payment_transaction CASCADE",
        "DROP TABLE IF EXISTS order_status CASCADE",
        "DROP TABLE IF EXISTS order_item CASCADE",
        "DROP TABLE IF EXISTS comment CASCADE",
        "DROP TABLE IF EXISTS book_author CASCADE",
        "DROP TABLE IF EXISTS cart_item CASCADE",
        "DROP TABLE IF EXISTS \"order\" CASCADE",
        "DROP TABLE IF EXISTS book CASCADE",
        "DROP TABLE IF EXISTS author CASCADE",
        "DROP TABLE IF EXISTS publisher CASCADE",
        "DROP TABLE IF EXISTS customer CASCADE"
    };

    for (const QString &sql : dropStatements) {
        if (!query.exec(sql)) {
            qCritical() << "Помилка при видаленні таблиці:" << query.lastError().text();
            qCritical() << "SQL:" << sql;
            return false;
        }
    }

    qInfo() << "Всі таблиці видалено. Створення нової схеми...";

    if (!createSchemaTables()) {
        qCritical() << "Помилка при створенні схеми!";
        return false;
    }

    qInfo() << "Схема створена. Заповнення тестовими даними...";

    if (!populateTestData(this, 30)) {
        qCritical() << "Помилка при заповненні тестовими даними!";
        return false;
    }

    qInfo() << "База даних успішно скинута та заповнена новими даними!";
    return true;
}

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent), m_isConnected(false)
{
    QString sqlPath = QCoreApplication::applicationDirPath() + "/sql";
    if (!loadSqlQueries(sqlPath)) {
        qCritical() << "ФАТАЛЬНА ПОМИЛКА: Не вдалося завантажити SQL запити з" << sqlPath;
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
    if(success) success &= executeQuery(query, getSqlQuery("DropPaymentStatusHistoryTable"), "Видалення payment_status_history");
    if(success) success &= executeQuery(query, getSqlQuery("DropPaymentTransactionTable"), "Видалення payment_transaction");
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
    if(success) success &= executeQuery(query, getSqlQuery("CreatePaymentTransactionTable"), "Створення payment_transaction");
    if(success) success &= executeQuery(query, getSqlQuery("CreateBookAuthorTable"), "Створення book_author");
    if(success) success &= executeQuery(query, getSqlQuery("CreateOrderItemTable"), "Створення order_item");
    if(success) success &= executeQuery(query, getSqlQuery("CreateOrderStatusTable"), "Створення order_status");
    if(success) success &= executeQuery(query, getSqlQuery("CreatePaymentStatusHistoryTable"), "Створення payment_status_history");
    if(success) success &= executeQuery(query, getSqlQuery("CreateCommentTable"), "Створення comment");
    if(success) success &= executeQuery(query, getSqlQuery("CreateCartItemTable"), "Створення cart_item");

    // Create indexes for hot read paths
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexOrderCustomerDate"), "Створення індексу idx_order_customer_date");
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexOrderStatusOrderDate"), "Створення індексу idx_order_status_order_date");
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexOrderItemOrder"), "Створення індексу idx_order_item_order");
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexCommentBookDate"), "Створення індексу idx_comment_book_date");
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexBookGenreLanguage"), "Створення індексу idx_book_genre_language");
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexBookTitleLower"), "Створення індексу idx_book_title_lower");
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexAuthorFullNameLower"), "Створення індексу idx_author_full_name_lower");
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexPaymentTransactionProviderOrder"), "Створення індексу idx_payment_transaction_provider_order");
    if(success) success &= executeQuery(query, getSqlQuery("CreateIndexPaymentStatusHistoryTransactionDate"), "Створення індексу idx_payment_status_history_tx_date");

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

#include <QDirIterator>

bool DatabaseManager::loadSqlQueries(const QString& directory)
{
    m_sqlQueries.clear();
    QDir sqlDir(directory);
    if (!sqlDir.exists()) {
        qCritical() << "Каталог SQL не знайдено:" << sqlDir.absolutePath();
        return false;
    }

    qInfo() << "Завантаження SQL запитів з каталогу (рекурсивно):" << sqlDir.absolutePath();
    
    // Используем QDirIterator для рекурсивного поиска всех .sql файлов
    QDirIterator::IteratorFlags flags = QDirIterator::Subdirectories;
    QDirIterator iterator(sqlDir.absolutePath(), QStringList() << "*.sql", QDir::Files, flags);
    bool allParsed = true;
    int fileCount = 0;

    while (iterator.hasNext()) {
        QString filePath = iterator.next();
        if (!parseSqlFile(filePath)) {
            qWarning() << "Не вдалося розібрати SQL файл:" << filePath;
            allParsed = false;
        }
        fileCount++;
    }

    qInfo() << QString("Завантажено %1 SQL запитів з %2 файлів.").arg(m_sqlQueries.count()).arg(fileCount);
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
