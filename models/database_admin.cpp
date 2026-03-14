#include "database.h"

#include <QDateTime>
#include <QDebug>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>
#include <QVariantMap>

QList<QVariantMap> DatabaseManager::getAllBooksForAdmin() const
{
    QList<QVariantMap> books;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot load books for admin: no database connection.";
        return books;
    }

    const QString sql = getSqlQuery("GetAllBooksForAdmin");
    if (sql.isEmpty()) {
        return books;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'GetAllBooksForAdmin':" << query.lastError().text();
        return books;
    }

    if (!query.exec()) {
        qCritical() << "Failed to execute 'GetAllBooksForAdmin':" << query.lastError().text();
        return books;
    }

    while (query.next()) {
        QVariantMap item;
        item["bookId"] = query.value("book_id").toInt();
        item["title"] = query.value("title").toString();
        item["price"] = query.value("price").toDouble();
        item["stockQuantity"] = query.value("stock_quantity").toInt();
        item["genre"] = query.value("genre").toString();
        item["language"] = query.value("language").toString();
        item["description"] = query.value("description").toString();
        item["coverImagePath"] = query.value("cover_image_path").toString();
        item["publicationDate"] = query.value("publication_date").toString();
        item["authors"] = query.value("authors").toString();
        books.append(item);
    }

    return books;
}

bool DatabaseManager::addBookForAdmin(const QString &title,
                                      double price,
                                      int stockQuantity,
                                      const QString &genre,
                                      const QString &language,
                                      const QString &description,
                                      const QString &coverImagePath,
                                      int &newBookId)
{
    newBookId = -1;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot add book: no database connection.";
        return false;
    }
    if (title.trimmed().isEmpty() || price < 0.0 || stockQuantity < 0) {
        qWarning() << "Cannot add book: invalid data.";
        return false;
    }

    const QString sql = getSqlQuery("InsertBookAdmin");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'InsertBookAdmin':" << query.lastError().text();
        return false;
    }

    query.bindValue(":title", title.trimmed());
    query.bindValue(":price", price);
    query.bindValue(":stock_quantity", stockQuantity);
    query.bindValue(":genre", genre.trimmed().isEmpty() ? QVariant(QVariant::String) : genre.trimmed());
    query.bindValue(":language", language.trimmed().isEmpty() ? QVariant(QVariant::String) : language.trimmed());
    query.bindValue(":description", description.trimmed().isEmpty() ? QVariant(QVariant::String) : description.trimmed());
    query.bindValue(":cover_image_path", coverImagePath.trimmed().isEmpty() ? QVariant(QVariant::String) : coverImagePath.trimmed());

    QVariant insertedId;
    if (!executeInsertQuery(query, "InsertBookAdmin", insertedId)) {
        return false;
    }

    newBookId = insertedId.toInt();
    return newBookId > 0;
}

bool DatabaseManager::updateBookByAdmin(int bookId,
                                        const QString &title,
                                        double price,
                                        int stockQuantity,
                                        const QString &genre,
                                        const QString &language,
                                        const QString &description,
                                        const QString &coverImagePath)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot update book: no database connection.";
        return false;
    }
    if (bookId <= 0 || title.trimmed().isEmpty() || price < 0.0 || stockQuantity < 0) {
        qWarning() << "Cannot update book: invalid data.";
        return false;
    }

    const QString sql = getSqlQuery("UpdateBookAdmin");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'UpdateBookAdmin':" << query.lastError().text();
        return false;
    }

    query.bindValue(":book_id", bookId);
    query.bindValue(":title", title.trimmed());
    query.bindValue(":price", price);
    query.bindValue(":stock_quantity", stockQuantity);
    query.bindValue(":genre", genre.trimmed().isEmpty() ? QVariant(QVariant::String) : genre.trimmed());
    query.bindValue(":language", language.trimmed().isEmpty() ? QVariant(QVariant::String) : language.trimmed());
    query.bindValue(":description", description.trimmed().isEmpty() ? QVariant(QVariant::String) : description.trimmed());
    query.bindValue(":cover_image_path", coverImagePath.trimmed().isEmpty() ? QVariant(QVariant::String) : coverImagePath.trimmed());

    if (!query.exec()) {
        qCritical() << "Failed to execute 'UpdateBookAdmin':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool DatabaseManager::increaseBookStockByAdmin(int bookId, int quantityToAdd)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot increase stock: no database connection.";
        return false;
    }
    if (bookId <= 0 || quantityToAdd <= 0) {
        qWarning() << "Cannot increase stock: invalid data.";
        return false;
    }

    const QString sql = getSqlQuery("IncreaseBookStockAdmin");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'IncreaseBookStockAdmin':" << query.lastError().text();
        return false;
    }

    query.bindValue(":book_id", bookId);
    query.bindValue(":quantity_to_add", quantityToAdd);

    if (!query.exec()) {
        qCritical() << "Failed to execute 'IncreaseBookStockAdmin':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool DatabaseManager::updateBookPriceByAdmin(int bookId, double price)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot update price: no database connection.";
        return false;
    }
    if (bookId <= 0 || price < 0.0) {
        qWarning() << "Cannot update price: invalid data.";
        return false;
    }

    const QString sql = getSqlQuery("UpdateBookPriceAdmin");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'UpdateBookPriceAdmin':" << query.lastError().text();
        return false;
    }

    query.bindValue(":book_id", bookId);
    query.bindValue(":price", price);

    if (!query.exec()) {
        qCritical() << "Failed to execute 'UpdateBookPriceAdmin':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool DatabaseManager::deleteBookByAdmin(int bookId)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot delete book: no database connection.";
        return false;
    }
    if (bookId <= 0) {
        return false;
    }

    const QString sql = getSqlQuery("DeleteBookAdmin");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'DeleteBookAdmin':" << query.lastError().text();
        return false;
    }

    query.bindValue(":book_id", bookId);
    if (!query.exec()) {
        qCritical() << "Failed to execute 'DeleteBookAdmin':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

QList<QVariantMap> DatabaseManager::getAllCommentsForAdmin() const
{
    QList<QVariantMap> comments;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot load comments for admin: no database connection.";
        return comments;
    }

    const QString sql = getSqlQuery("GetAllCommentsForAdmin");
    if (sql.isEmpty()) {
        return comments;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'GetAllCommentsForAdmin':" << query.lastError().text();
        return comments;
    }

    if (!query.exec()) {
        qCritical() << "Failed to execute 'GetAllCommentsForAdmin':" << query.lastError().text();
        return comments;
    }

    while (query.next()) {
        QVariantMap item;
        item["commentId"] = query.value("comment_id").toInt();
        item["bookId"] = query.value("book_id").toInt();
        item["bookTitle"] = query.value("book_title").toString();
        item["customerId"] = query.value("customer_id").toInt();
        item["authorName"] = query.value("author_name").toString();
        item["rating"] = query.value("rating").toInt();
        item["commentText"] = query.value("comment_text").toString();
        item["commentDate"] = query.value("comment_date").toDateTime().toString(Qt::ISODate);
        comments.append(item);
    }

    return comments;
}

bool DatabaseManager::deleteCommentByAdmin(int commentId)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot delete comment: no database connection.";
        return false;
    }
    if (commentId <= 0) {
        return false;
    }

    const QString sql = getSqlQuery("DeleteCommentByIdAdmin");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'DeleteCommentByIdAdmin':" << query.lastError().text();
        return false;
    }

    query.bindValue(":comment_id", commentId);
    if (!query.exec()) {
        qCritical() << "Failed to execute 'DeleteCommentByIdAdmin':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

QList<QVariantMap> DatabaseManager::getAllCustomersForAdmin() const
{
    QList<QVariantMap> customers;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot load customers for admin: no database connection.";
        return customers;
    }

    const QString sql = getSqlQuery("GetAllCustomersForAdmin");
    if (sql.isEmpty()) {
        return customers;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'GetAllCustomersForAdmin':" << query.lastError().text();
        return customers;
    }

    if (!query.exec()) {
        qCritical() << "Failed to execute 'GetAllCustomersForAdmin':" << query.lastError().text();
        return customers;
    }

    while (query.next()) {
        const QString firstName = query.value("first_name").toString();
        const QString lastName = query.value("last_name").toString();

        QVariantMap item;
        item["customerId"] = query.value("customer_id").toInt();
        item["firstName"] = firstName;
        item["lastName"] = lastName;
        item["fullName"] = (firstName + " " + lastName).trimmed();
        item["email"] = query.value("email").toString();
        item["phone"] = query.value("phone").toString();
        item["address"] = query.value("address").toString();
        item["joinDate"] = query.value("join_date").toDate().toString("yyyy-MM-dd");
        item["loyaltyPoints"] = query.value("loyalty_points").toInt();
        item["isAdmin"] = query.value("is_admin").toBool();
        customers.append(item);
    }

    return customers;
}

bool DatabaseManager::setCustomerAdminRole(int customerId, bool isAdmin)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot update customer role: no database connection.";
        return false;
    }
    if (customerId <= 0) {
        return false;
    }

    const QString sql = getSqlQuery("SetCustomerAdminRole");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'SetCustomerAdminRole':" << query.lastError().text();
        return false;
    }

    query.bindValue(":customer_id", customerId);
    query.bindValue(":is_admin", isAdmin);
    if (!query.exec()) {
        qCritical() << "Failed to execute 'SetCustomerAdminRole':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

QList<QVariantMap> DatabaseManager::getAllOrdersForAdmin() const
{
    QList<QVariantMap> orders;
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot load orders for admin: no database connection.";
        return orders;
    }

    const QString sql = getSqlQuery("GetAllOrdersForAdmin");
    if (sql.isEmpty()) {
        return orders;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'GetAllOrdersForAdmin':" << query.lastError().text();
        return orders;
    }

    if (!query.exec()) {
        qCritical() << "Failed to execute 'GetAllOrdersForAdmin':" << query.lastError().text();
        return orders;
    }

    while (query.next()) {
        QVariantMap item;
        item["orderId"] = query.value("order_id").toInt();
        item["customerId"] = query.value("customer_id").toInt();
        item["customerName"] = query.value("customer_name").toString();
        item["orderDate"] = query.value("order_date").toString();
        item["totalAmount"] = query.value("total_amount").toDouble();
        item["shippingAddress"] = query.value("shipping_address").toString();
        item["paymentMethod"] = query.value("payment_method").toString();
        item["lastStatus"] = query.value("last_status").toString();
        orders.append(item);
    }

    return orders;
}

bool DatabaseManager::addOrderStatusByAdmin(int orderId, const QString &status, const QString &trackingNumber)
{
    if (!m_isConnected || !m_db.isOpen()) {
        qWarning() << "Cannot add order status: no database connection.";
        return false;
    }
    if (orderId <= 0 || status.trimmed().isEmpty()) {
        return false;
    }

    const QString sql = getSqlQuery("InsertOrderStatusByAdmin");
    if (sql.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.prepare(sql)) {
        qCritical() << "Failed to prepare 'InsertOrderStatusByAdmin':" << query.lastError().text();
        return false;
    }

    query.bindValue(":order_id", orderId);
    query.bindValue(":status", status.trimmed());
    query.bindValue(":tracking_number", trackingNumber.trimmed());
    if (!query.exec()) {
        qCritical() << "Failed to execute 'InsertOrderStatusByAdmin':" << query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}
