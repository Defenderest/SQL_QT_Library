#include "appcontext.h"
#include <QDebug>
#include <QCryptographicHash>
#include <QSqlQuery>
#include <QSqlError>

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

QString AppContext::authError() const
{
    return m_authError;
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
    if ((page == "cart" || page == "orders") && !loggedIn()) {
        emit infoMessage("Щоб відкрити цей розділ, увійдіть у профіль");
        emit navigateToPage("profile");
        return;
    }

    if (page == "admin" && !isAdmin()) {
        emit infoMessage("Адмін-панель доступна лише адміністраторам");
        emit navigateToPage(loggedIn() ? "home" : "profile");
        return;
    }

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
    if (!loggedIn()) {
        emit infoMessage("Щоб переглядати замовлення, увійдіть у профіль");
        emit navigateToPage("profile");
        return;
    }
    emit showOrderDetailsRequested(orderId);
}

void AppContext::checkout()
{
    if (!loggedIn()) {
        emit infoMessage("Щоб оформити замовлення, увійдіть у профіль");
        emit navigateToPage("profile");
        return;
    }
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
    if (customerId > 0) {
        emit loginRequested();
    }
}

void AppContext::requestLogin()
{
    emit navigateToPage("profile");
}

bool AppContext::loginWithCredentials(const QString& email, const QString& password)
{
    setAuthError("");

    if (!m_dbManager) {
        setAuthError("Помилка підключення до бази даних");
        emit errorOccurred(m_authError);
        return false;
    }

    const QString cleanEmail = email.trimmed();
    if (cleanEmail.isEmpty() || password.isEmpty()) {
        setAuthError("Введіть email та пароль");
        return false;
    }

    const CustomerLoginInfo loginInfo = m_dbManager->getCustomerLoginInfo(cleanEmail);
    if (!loginInfo.found) {
        setAuthError("Невірний email або пароль");
        return false;
    }

    const QString enteredPasswordHashHex = QString::fromUtf8(
        QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());

    if (enteredPasswordHashHex != loginInfo.passwordHash) {
        setAuthError("Невірний email або пароль");
        return false;
    }

    setCurrentCustomerId(loginInfo.customerId);
    setIsAdmin(loginInfo.isAdmin);
    emit loginRequested();
    return true;
}

bool AppContext::registerWithCredentials(const QString& firstName,
                                         const QString& lastName,
                                         const QString& email,
                                         const QString& password,
                                         const QString& confirmPassword)
{
    setAuthError("");

    if (!m_dbManager) {
        setAuthError("Помилка підключення до бази даних");
        emit errorOccurred(m_authError);
        return false;
    }

    CustomerRegistrationInfo regInfo;
    regInfo.firstName = firstName.trimmed();
    regInfo.lastName = lastName.trimmed();
    regInfo.email = email.trimmed();
    regInfo.password = password;

    if (regInfo.firstName.isEmpty() || regInfo.lastName.isEmpty() ||
        regInfo.email.isEmpty() || regInfo.password.isEmpty()) {
        setAuthError("Заповніть усі поля");
        return false;
    }

    if (password != confirmPassword) {
        setAuthError("Паролі не співпадають");
        return false;
    }

    int newId = -1;
    if (!m_dbManager->registerCustomer(regInfo, newId) || newId <= 0) {
        const QString dbError = m_dbManager->lastError().text().toLower();
        if (dbError.contains("duplicate") || dbError.contains("already exists")) {
            setAuthError("Користувач з таким email вже існує");
        } else {
            setAuthError("Не вдалося зареєструватися. Спробуйте пізніше");
        }
        return false;
    }

    setCurrentCustomerId(newId);
    setIsAdmin(false);
    emit loginRequested();
    return true;
}

QString AppContext::getBooksCatalogForAI()
{
    if (!m_dbManager) {
        qWarning() << "Database manager not set!";
        return "";
    }
    
    qDebug() << "📚 Отримання каталогу книг для AI...";
    
    QStringList contextParts;
    
    // Отримуємо книги напряму з БД
    QSqlQuery query(m_dbManager->database());
    QString sql = "SELECT b.book_id, b.title, b.price, b.stock_quantity, b.genre, "
                  "STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors "
                  "FROM book b "
                  "LEFT JOIN book_author ba ON b.book_id = ba.book_id "
                  "LEFT JOIN author a ON ba.author_id = a.author_id "
                  "WHERE b.stock_quantity > 0 "
                  "GROUP BY b.book_id, b.title, b.price, b.stock_quantity, b.genre "
                  "ORDER BY b.title "
                  "LIMIT 100";
    
    if (!query.exec(sql)) {
        qWarning() << "Failed to get books for AI:" << query.lastError().text();
        return "";
    }
    
    QStringList booksList;
    int count = 0;
    
    while (query.next()) {
        QString title = query.value("title").toString();
        QString authors = query.value("authors").toString();
        double price = query.value("price").toDouble();
        int stock = query.value("stock_quantity").toInt();
        QString genre = query.value("genre").toString();
        
        QString bookInfo = title;
        if (!authors.isEmpty()) bookInfo += " | Автор: " + authors;
        if (!genre.isEmpty()) bookInfo += " | Жанр: " + genre;
        bookInfo += " | Ціна: " + QString::number(price, 'f', 2) + " грн";
        bookInfo += " | В наявності: " + QString::number(stock) + " шт";
        
        booksList.append(bookInfo);
        count++;
    }
    
    if (count > 0) {
        contextParts.append("📚 КНИГИ В НАЯВНОСТІ (" + QString::number(count) + "):\n" + booksList.join("\n"));
    }
    
    // Отримуємо жанри
    QSqlQuery genreQuery(m_dbManager->database());
    if (genreQuery.exec("SELECT DISTINCT genre FROM book WHERE genre IS NOT NULL AND genre != '' ORDER BY genre")) {
        QStringList genres;
        while (genreQuery.next()) {
            genres.append(genreQuery.value(0).toString());
        }
        if (!genres.isEmpty()) {
            contextParts.append("\n📂 ЖАНРИ: " + genres.join(", "));
        }
    }
    
    // Отримуємо авторів
    QSqlQuery authorQuery(m_dbManager->database());
    if (authorQuery.exec("SELECT first_name || ' ' || last_name AS name FROM author ORDER BY last_name, first_name LIMIT 50")) {
        QStringList authors;
        while (authorQuery.next()) {
            authors.append(authorQuery.value(0).toString());
        }
        if (!authors.isEmpty()) {
            contextParts.append("\n✍️ АВТОРИ: " + authors.join(", "));
        }
    }
    
    QString result = contextParts.join("\n");
    qDebug() << "✅ Отримано" << count << "книг для AI";
    
    return result;
}

void AppContext::setAuthError(const QString& message)
{
    if (m_authError == message) {
        return;
    }
    m_authError = message;
    emit authErrorChanged();
}
