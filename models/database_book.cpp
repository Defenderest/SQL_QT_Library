#include "database.h"
#include <QDebug>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>
#include <QStringList>
#include <QDate>

QList<BookDisplayInfo> DatabaseManager::getAllBooksForDisplay(int limit, int offset) const
{
    QList<BookDisplayInfo> books;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо отримати книги: немає активного з'єднання з БД.";
        return books;
    }

    QString sql = getSqlQuery("GetAllBooksForDisplay");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetAllBooksForDisplay' не знайдено.";
        return books;
    }

    // Додаємо LIMIT та OFFSET, якщо вони вказані
    if (limit > 0) {
        sql += QString(" LIMIT %1 OFFSET %2").arg(limit).arg(offset);
    }

    QSqlQuery query(m_db);
    qInfo() << "Виконання SQL 'GetAllBooksForDisplay' для отримання книг для відображення...";
    qDebug() << "SQL запит:" << sql; // Для налагодження

    if (!query.exec(sql)) {
        qCritical() << "Помилка при виконанні 'GetAllBooksForDisplay':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << sql;
        return books;
    }

    qInfo() << "Книги успішно отримано. Обробка результатів...";
    int count = 0;
    while (query.next()) {
        BookDisplayInfo bookInfo;
        bookInfo.bookId = query.value("book_id").toInt();
        bookInfo.title = query.value("title").toString();
        bookInfo.price = query.value("price").toDouble();
        bookInfo.coverImagePath = query.value("cover_image_path").toString();
        bookInfo.stockQuantity = query.value("stock_quantity").toInt();
        bookInfo.authors = query.value("authors").toString();
        bookInfo.genre = query.value("genre").toString();
        bookInfo.found = true;

        if (query.value("authors").isNull()) {
            bookInfo.authors = "";
        }


        books.append(bookInfo);
        count++;
    }
    qInfo() << "Оброблено" << count << "книг для відображення.";

    return books;
}


QList<BookDisplayInfo> DatabaseManager::getFilteredBooksForDisplay(const BookFilterCriteria &criteria) const
{
    QList<BookDisplayInfo> books;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо отримати відфільтровані книги: немає активного з'єднання з БД.";
        return books;
    }

    QString sqlBase = getSqlQuery("GetFilteredBooksForDisplayBase");
    if (sqlBase.isEmpty()) {
        qCritical() << "SQL запит 'GetFilteredBooksForDisplayBase' не знайдено.";
        return books;
    }

    QString sql = sqlBase;

    QStringList whereConditions;
    QMap<QString, QVariant> bindValues;

    if (!criteria.genres.isEmpty()) {
        QStringList genrePlaceholders;
        for (int i = 0; i < criteria.genres.size(); ++i) {
            QString placeholder = QString(":genre_%1").arg(i);
            genrePlaceholders << placeholder;
            bindValues[placeholder] = criteria.genres[i];
        }
        whereConditions << QString("b.genre IN (%1)").arg(genrePlaceholders.join(", "));
    }

    if (!criteria.languages.isEmpty()) {
        QStringList langPlaceholders;
        for (int i = 0; i < criteria.languages.size(); ++i) {
            QString placeholder = QString(":lang_%1").arg(i);
            langPlaceholders << placeholder;
            bindValues[placeholder] = criteria.languages[i];
        }
        whereConditions << QString("b.language IN (%1)").arg(langPlaceholders.join(", "));
    }

    if (criteria.minPrice >= 0.0) {
        whereConditions << "b.price >= :minPrice";
        bindValues[":minPrice"] = criteria.minPrice;
    }

    if (criteria.maxPrice >= 0.0) {
        whereConditions << "b.price <= :maxPrice";
        bindValues[":maxPrice"] = criteria.maxPrice;
    }

    if (criteria.inStockOnly) {
        whereConditions << "b.stock_quantity > 0";
    }

    if (!whereConditions.isEmpty()) {
        sql += "\nWHERE " + whereConditions.join(" AND ");
    }

    sql += R"(
        GROUP BY b.book_id, b.title, b.price, b.cover_image_path, b.stock_quantity, b.genre, b.language, p.name
        ORDER BY b.title;
    )";

    QSqlQuery query(m_db);
    query.prepare(sql);

    for (auto it = bindValues.constBegin(); it != bindValues.constEnd(); ++it) {
        query.bindValue(it.key(), it.value());
    }

    qInfo() << "Виконання SQL для отримання відфільтрованих книг...";
    qDebug() << "SQL:" << sql;
    qDebug() << "Прив'язані значення:" << bindValues;

    if (!query.exec()) {
        qCritical() << "Помилка при отриманні відфільтрованого списку книг:";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        return books;
    }

    qInfo() << "Відфільтровані книги успішно отримано. Обробка результатів...";
    int count = 0;
    while (query.next()) {
        BookDisplayInfo bookInfo;
        bookInfo.bookId = query.value("book_id").toInt();
        bookInfo.title = query.value("title").toString();
        bookInfo.price = query.value("price").toDouble();
        bookInfo.coverImagePath = query.value("cover_image_path").toString();
        bookInfo.stockQuantity = query.value("stock_quantity").toInt();
        bookInfo.authors = query.value("authors").toString();
        bookInfo.genre = query.value("genre").toString();

        bookInfo.found = true;

        if (query.value("authors").isNull()) {
            bookInfo.authors = "";
        }

        books.append(bookInfo);
        count++;
    }
    qInfo() << "Оброблено" << count << "відфільтрованих книг.";

    return books;
}

QStringList DatabaseManager::getAllGenres() const
{
    QStringList genres;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо отримати жанри: немає активного з'єднання з БД.";
        return genres;
    }

    const QString sql = getSqlQuery("GetAllDistinctGenres");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetAllDistinctGenres' не знайдено.";
        return genres;
    }

    QSqlQuery query(m_db);
    qInfo() << "Виконання SQL 'GetAllDistinctGenres' для отримання всіх унікальних жанрів...";
    if (!query.exec(sql)) {
        qCritical() << "Помилка при виконанні 'GetAllDistinctGenres':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << sql;
        return genres;
    }

    while (query.next()) {
        genres.append(query.value(0).toString());
    }
    qInfo() << "Отримано" << genres.size() << "унікальних жанрів.";
    return genres;
}

QStringList DatabaseManager::getAllLanguages() const
{
    QStringList languages;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо отримати мови: немає активного з'єднання з БД.";
        return languages;
    }

    const QString sql = getSqlQuery("GetAllDistinctLanguages");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetAllDistinctLanguages' не знайдено.";
        return languages;
    }

    QSqlQuery query(m_db);
    qInfo() << "Виконання SQL 'GetAllDistinctLanguages' для отримання всіх унікальних мов...";
    if (!query.exec(sql)) {
        qCritical() << "Помилка при виконанні 'GetAllDistinctLanguages':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << sql;
        return languages;
    }

    while (query.next()) {
        languages.append(query.value(0).toString());
    }
    qInfo() << "Отримано" << languages.size() << "унікальних мов.";
    return languages;
}

BookDetailsInfo DatabaseManager::getBookDetails(int bookId) const
{
    BookDetailsInfo details;
    details.found = false;
    if (!m_isConnected || !m_db.isOpen() || bookId <= 0) {
        qWarning() << "Неможливо отримати деталі книги: немає з'єднання або невірний bookId.";
        return details;
    }

    const QString sql = getSqlQuery("GetBookDetailsById");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetBookDetailsById' не знайдено.";
        return details;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'GetBookDetailsById':" << query.lastError().text();
        return details;
    }
    query.bindValue(":bookId", bookId);

    qInfo() << "Виконання SQL 'GetBookDetailsById' для ID книги:" << bookId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'GetBookDetailsById' для book ID '" << bookId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        return details;
    }

    if (query.next()) {
        details.bookId = query.value("book_id").toInt();
        details.title = query.value("title").toString();
        details.price = query.value("price").toDouble();
        details.coverImagePath = query.value("cover_image_path").toString();
        details.stockQuantity = query.value("stock_quantity").toInt();
        details.genre = query.value("genre").toString();
        details.description = query.value("description").toString();
        details.publicationDate = query.value("publication_date").toDate();
        details.isbn = query.value("isbn").toString();
        details.pageCount = query.value("page_count").toInt();
        details.language = query.value("language").toString();
        details.publisherName = query.value("publisher_name").toString();
        details.authors = query.value("authors").toString();
        if (query.value("authors").isNull()) {
            details.authors = "";
        }
        details.found = true;
        qInfo() << "Деталі книги знайдено для ID книги:" << bookId;
    } else {
        qInfo() << "Деталі книги не знайдено для ID книги:" << bookId;

    }


    details.comments = getBookComments(bookId);
    qInfo() << "Отримано" << details.comments.size() << "коментарів для ID книги:" << bookId;


    return details;
}

BookDisplayInfo DatabaseManager::getBookDisplayInfoById(int bookId) const
{
    BookDisplayInfo bookInfo;
    bookInfo.found = false;
    if (!m_isConnected || !m_db.isOpen() || bookId <= 0) {
        qWarning() << "Неможливо отримати BookDisplayInfo: немає з'єднання або невірний bookId.";
        return bookInfo;
    }

    const QString sql = getSqlQuery("GetBookDisplayInfoById");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetBookDisplayInfoById' не знайдено.";
        return bookInfo;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'GetBookDisplayInfoById':" << query.lastError().text();
        return bookInfo;
    }
    query.bindValue(":bookId", bookId);

    qInfo() << "Виконання SQL 'GetBookDisplayInfoById' для ID книги:" << bookId;
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'GetBookDisplayInfoById' для book ID '" << bookId << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        return bookInfo;
    }

    if (query.next()) {
        bookInfo.bookId = query.value("book_id").toInt();
        bookInfo.title = query.value("title").toString();
        bookInfo.price = query.value("price").toDouble();
        bookInfo.coverImagePath = query.value("cover_image_path").toString();
        bookInfo.stockQuantity = query.value("stock_quantity").toInt();
        bookInfo.authors = query.value("authors").toString();
        bookInfo.genre = query.value("genre").toString();
        if (query.value("authors").isNull()) {
            bookInfo.authors = "";
        }
        bookInfo.found = true;
        qInfo() << "BookDisplayInfo знайдено для ID книги:" << bookId;
    } else {
        qInfo() << "BookDisplayInfo не знайдено для ID книги:" << bookId;
    }

    return bookInfo;
}

QList<BookDisplayInfo> DatabaseManager::getBooksByGenre(const QString &genre, int limit) const
{
    QList<BookDisplayInfo> books;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо отримати книги за жанром: немає активного з'єднання з БД.";
        return books;
    }
    if (genre.isEmpty()) {
        qWarning() << "Неможливо отримати книги: не вказано жанр.";
        return books;
    }

    const QString sql = getSqlQuery("GetBooksByGenre");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetBooksByGenre' не знайдено.";
        return books;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'GetBooksByGenre':" << query.lastError().text();
        return books;
    }
    query.bindValue(":genre", genre);
    query.bindValue(":limit", limit > 0 ? limit : 10);

    qInfo() << "Виконання SQL 'GetBooksByGenre' для жанру:" << genre << "з лімітом:" << query.boundValue(":limit").toInt();
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'GetBooksByGenre' для жанру '" << genre << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return books;
    }

    qInfo() << "Книги за жанром" << genre << "успішно отримано. Обробка результатів...";
    int count = 0;
    while (query.next()) {
        BookDisplayInfo bookInfo;
        bookInfo.bookId = query.value("book_id").toInt();
        bookInfo.title = query.value("title").toString();
        bookInfo.price = query.value("price").toDouble();
        bookInfo.coverImagePath = query.value("cover_image_path").toString();
        bookInfo.stockQuantity = query.value("stock_quantity").toInt();
        bookInfo.authors = query.value("authors").toString();
        bookInfo.genre = query.value("genre").toString();
        bookInfo.found = true;

        if (query.value("authors").isNull()) {
            bookInfo.authors = "";
        }

        books.append(bookInfo);
        count++;
    }
    qInfo() << "Оброблено" << count << "книг за жанром" << genre;

    return books;
}

QList<SearchSuggestionInfo> DatabaseManager::getSearchSuggestions(const QString &prefix, int limit) const
{
    QList<SearchSuggestionInfo> suggestions;

    if (!m_isConnected || !m_db.isOpen() || prefix.isEmpty()) {
        qWarning() << "Неможливо отримати пропозиції пошуку: немає з'єднання або префікс порожній.";
        return suggestions;
    }

    const QString sql = getSqlQuery("GetSearchSuggestions");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetSearchSuggestions' не знайдено.";
        return suggestions;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'GetSearchSuggestions':" << query.lastError().text();
        return suggestions;
    }
    query.bindValue(":prefix", prefix);
    query.bindValue(":total_limit", limit > 0 ? limit : 10);

    qInfo() << "Виконання SQL 'GetSearchSuggestions' для префікса:" << prefix << "з лімітом:" << query.boundValue(":total_limit").toInt();
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'GetSearchSuggestions' для префікса '" << prefix << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return suggestions;
    }

    qInfo() << "Розширені пропозиції успішно отримано. Обробка результатів...";
    int count = 0;
    while (query.next()) {
        SearchSuggestionInfo suggestion;
        QString typeStr = query.value("type").toString();
        suggestion.id = query.value("id").toInt();
        suggestion.displayText = query.value("display_text").toString();
        suggestion.imagePath = query.value("image_path").toString();
        suggestion.price = query.value("price").toDouble();

        if (typeStr == "book") {
            suggestion.type = SearchSuggestionInfo::Book;
        } else if (typeStr == "author") {
            suggestion.type = SearchSuggestionInfo::Author;
        } else {
            qWarning() << "Зустрінуто невідомий тип пропозиції:" << typeStr;
            continue;
        }

        suggestions.append(suggestion);
        count++;
    }
    qInfo() << "Оброблено" << count << "розширених пропозицій для префікса" << prefix;

    return suggestions;
}

QList<BookDisplayInfo> DatabaseManager::getSimilarBooks(int currentBookId, const QString &genre, int limit) const
{
    QList<BookDisplayInfo> books;
    if (!m_isConnected || !m_db.isOpen() || genre.isEmpty() || currentBookId <= 0) {
        qWarning() << "Неможливо отримати схожі книги: немає з'єднання, порожній жанр або невірний currentBookId.";
        return books;
    }

    const QString sql = getSqlQuery("GetSimilarBooksByGenre");
    if (sql.isEmpty()) {
        qCritical() << "SQL запит 'GetSimilarBooksByGenre' не знайдено.";
        return books;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Помилка підготовки запиту 'GetSimilarBooksByGenre':" << query.lastError().text();
        return books;
    }
    query.bindValue(":genre", genre);
    query.bindValue(":currentBookId", currentBookId);
    query.bindValue(":limit", limit > 0 ? limit : 5);

    qInfo() << "Виконання SQL 'GetSimilarBooksByGenre' для жанру:" << genre << "виключаючи книгу з ID:" << currentBookId << "з лімітом:" << query.boundValue(":limit").toInt();
    if (!query.exec()) {
        qCritical() << "Помилка при виконанні 'GetSimilarBooksByGenre' для жанру '" << genre << "':";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << query.lastQuery();
        qCritical() << "Прив'язані значення:" << query.boundValues();
        return books;
    }

    qInfo() << "Схожі книги за жанром" << genre << "успішно отримано. Обробка результатів...";
    int count = 0;
    while (query.next()) {
        BookDisplayInfo bookInfo;
        bookInfo.bookId = query.value("book_id").toInt();
        bookInfo.title = query.value("title").toString();
        bookInfo.price = query.value("price").toDouble();
        bookInfo.coverImagePath = query.value("cover_image_path").toString();
        bookInfo.stockQuantity = query.value("stock_quantity").toInt();
        bookInfo.authors = query.value("authors").toString();
        bookInfo.genre = query.value("genre").toString();
        bookInfo.found = true;

        if (query.value("authors").isNull()) {
            bookInfo.authors = "";
        }

        books.append(bookInfo);
        count++;
    }
    qInfo() << "Оброблено" << count << "схожих книг за жанром" << genre;

    return books;
}

int DatabaseManager::getTotalBookCount() const
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Неможливо отримати загальну кількість книг: немає активного з'єднання з БД.";
        return 0;
    }

    const QString sql = "SELECT COUNT(*) FROM books;"; // Простий запит для підрахунку
    QSqlQuery query(m_db);
    qInfo() << "Виконання SQL для отримання загальної кількості книг...";
    if (!query.exec(sql)) {
        qCritical() << "Помилка при отриманні загальної кількості книг:";
        qCritical() << query.lastError().text();
        qCritical() << "SQL запит:" << sql;
        return 0;
    }

    if (query.next()) {
        int count = query.value(0).toInt();
        qInfo() << "Загальна кількість книг:" << count;
        return count;
    }
    return 0;
}
