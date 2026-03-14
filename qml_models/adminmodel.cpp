#include "adminmodel.h"

#include "../core/database.h"

AdminModel::AdminModel(QObject *parent)
    : QObject(parent)
{
}

DatabaseManager* AdminModel::dbManager() const
{
    return m_dbManager;
}

void AdminModel::setDbManager(DatabaseManager *dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
        setReady(m_dbManager != nullptr);
    }
}

bool AdminModel::ready() const
{
    return m_ready;
}

QVariantList AdminModel::books() const
{
    return m_books;
}

QVariantList AdminModel::comments() const
{
    return m_comments;
}

QVariantList AdminModel::orders() const
{
    return m_orders;
}

QVariantList AdminModel::users() const
{
    return m_users;
}

void AdminModel::loadAllData()
{
    reloadBooks();
    reloadComments();
    reloadOrders();
    reloadUsers();
}

void AdminModel::reloadBooks()
{
    if (!m_dbManager) {
        m_books.clear();
        emit booksChanged();
        return;
    }

    m_books = toVariantList(m_dbManager->getAllBooksForAdmin());
    emit booksChanged();
}

void AdminModel::reloadComments()
{
    if (!m_dbManager) {
        m_comments.clear();
        emit commentsChanged();
        return;
    }

    m_comments = toVariantList(m_dbManager->getAllCommentsForAdmin());
    emit commentsChanged();
}

void AdminModel::reloadOrders()
{
    if (!m_dbManager) {
        m_orders.clear();
        emit ordersChanged();
        return;
    }

    m_orders = toVariantList(m_dbManager->getAllOrdersForAdmin());
    emit ordersChanged();
}

void AdminModel::reloadUsers()
{
    if (!m_dbManager) {
        m_users.clear();
        emit usersChanged();
        return;
    }

    m_users = toVariantList(m_dbManager->getAllCustomersForAdmin());
    emit usersChanged();
}

bool AdminModel::addBook(const QString &title,
                         double price,
                         int stockQuantity,
                         const QString &genre,
                         const QString &language,
                         const QString &description,
                         const QString &coverImagePath)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager is not set");
        return false;
    }

    int newBookId = -1;
    const bool ok = m_dbManager->addBookForAdmin(
        title, price, stockQuantity, genre, language, description, coverImagePath, newBookId);
    if (!ok) {
        emit errorOccurred("Failed to add book");
        return false;
    }

    reloadBooks();
    emit infoMessage("Book added");
    return true;
}

bool AdminModel::updateBook(int bookId,
                            const QString &title,
                            double price,
                            int stockQuantity,
                            const QString &genre,
                            const QString &language,
                            const QString &description,
                            const QString &coverImagePath)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager is not set");
        return false;
    }

    const bool ok = m_dbManager->updateBookByAdmin(
        bookId, title, price, stockQuantity, genre, language, description, coverImagePath);
    if (!ok) {
        emit errorOccurred("Failed to update book");
        return false;
    }

    reloadBooks();
    emit infoMessage("Book updated");
    return true;
}

bool AdminModel::addBookStock(int bookId, int quantityToAdd)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager is not set");
        return false;
    }

    if (quantityToAdd <= 0) {
        emit errorOccurred("Вкажіть коректну кількість для додавання");
        return false;
    }

    const bool ok = m_dbManager->increaseBookStockByAdmin(bookId, quantityToAdd);
    if (!ok) {
        emit errorOccurred("Не вдалося оновити залишок книги");
        return false;
    }

    reloadBooks();
    emit infoMessage(QStringLiteral("Додано %1 шт. до залишку").arg(quantityToAdd));
    return true;
}

bool AdminModel::updateBookPrice(int bookId, double price)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager is not set");
        return false;
    }

    const bool ok = m_dbManager->updateBookPriceByAdmin(bookId, price);
    if (!ok) {
        emit errorOccurred("Failed to update price");
        return false;
    }

    reloadBooks();
    emit infoMessage("Price updated");
    return true;
}

bool AdminModel::deleteBook(int bookId)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager is not set");
        return false;
    }

    const bool ok = m_dbManager->deleteBookByAdmin(bookId);
    if (!ok) {
        emit errorOccurred("Failed to delete book");
        return false;
    }

    reloadBooks();
    emit infoMessage("Book deleted");
    return true;
}

bool AdminModel::deleteComment(int commentId)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager is not set");
        return false;
    }

    const bool ok = m_dbManager->deleteCommentByAdmin(commentId);
    if (!ok) {
        emit errorOccurred("Failed to delete comment");
        return false;
    }

    reloadComments();
    emit infoMessage("Comment deleted");
    return true;
}

bool AdminModel::setUserAdminRole(int customerId, bool isAdmin)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager is not set");
        return false;
    }

    const bool ok = m_dbManager->setCustomerAdminRole(customerId, isAdmin);
    if (!ok) {
        emit errorOccurred("Failed to update user role");
        return false;
    }

    reloadUsers();
    emit infoMessage("User role updated");
    return true;
}

bool AdminModel::addOrderStatus(int orderId, const QString &status, const QString &trackingNumber)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager is not set");
        return false;
    }

    const bool ok = m_dbManager->addOrderStatusByAdmin(orderId, status, trackingNumber);
    if (!ok) {
        emit errorOccurred("Failed to add order status");
        return false;
    }

    reloadOrders();
    emit infoMessage("Order status added");
    return true;
}

QVariantList AdminModel::toVariantList(const QList<QVariantMap> &items) const
{
    QVariantList result;
    result.reserve(items.size());
    for (const QVariantMap &item : items) {
        result.append(item);
    }
    return result;
}

void AdminModel::setReady(bool ready)
{
    if (m_ready != ready) {
        m_ready = ready;
        emit readyChanged();
    }
}
