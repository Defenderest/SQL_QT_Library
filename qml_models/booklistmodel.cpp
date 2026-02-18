#include "booklistmodel.h"
#include "../core/database.h"
#include <QDebug>

BookListModel::BookListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int BookListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_books.count();
}

QVariant BookListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_books.count())
        return QVariant();

    const BookDisplayInfo &book = m_books.at(index.row());

    switch (role) {
    case BookIdRole:
        return book.bookId;
    case TitleRole:
        return book.title;
    case AuthorsRole:
        return book.authors;
    case PriceRole:
        return book.price;
    case CoverImagePathRole:
        return book.coverImagePath;
    case StockQuantityRole:
        return book.stockQuantity;
    case GenreRole:
        return book.genre;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> BookListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[BookIdRole] = "bookId";
    roles[TitleRole] = "title";
    roles[AuthorsRole] = "authors";
    roles[PriceRole] = "price";
    roles[CoverImagePathRole] = "coverImagePath";
    roles[StockQuantityRole] = "stockQuantity";
    roles[GenreRole] = "genre";
    return roles;
}

DatabaseManager* BookListModel::dbManager() const
{
    return m_dbManager;
}

void BookListModel::setDbManager(DatabaseManager* dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
    }
}

int BookListModel::count() const
{
    return m_books.count();
}

void BookListModel::loadAllBooks()
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager not set");
        return;
    }

    beginResetModel();
    m_books = m_dbManager->getAllBooksForDisplay();
    endResetModel();
    emit countChanged();
}

void BookListModel::loadPopularBooks()
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager not set");
        return;
    }

    beginResetModel();
    m_books = m_dbManager->getBooksByGenre("Фентезі", 8);
    endResetModel();
    emit countChanged();
}

void BookListModel::loadNewArrivals()
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager not set");
        return;
    }

    beginResetModel();
    m_books = m_dbManager->getBooksByGenre("Класика", 8);
    endResetModel();
    emit countChanged();
}

QStringList BookListModel::getAvailableGenres() const
{
    if (!m_dbManager) {
        return {};
    }
    return m_dbManager->getAllGenres();
}

QStringList BookListModel::getAvailableLanguages() const
{
    if (!m_dbManager) {
        return {};
    }
    return m_dbManager->getAllLanguages();
}

void BookListModel::loadFilteredBooks(const QString& genre, const QString& language,
                                       double minPrice, double maxPrice, bool inStockOnly)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager not set");
        return;
    }

    BookFilterCriteria criteria;
    if (!genre.isEmpty()) criteria.genres.append(genre);
    if (!language.isEmpty()) criteria.languages.append(language);
    criteria.minPrice = minPrice;
    criteria.maxPrice = maxPrice;
    criteria.inStockOnly = inStockOnly;

    beginResetModel();
    m_books = m_dbManager->getFilteredBooksForDisplay(criteria);
    endResetModel();
    emit countChanged();
}

void BookListModel::searchBooks(const QString& query)
{
    if (!m_dbManager || query.isEmpty()) {
        clear();
        return;
    }

    // TODO: Implement search in DatabaseManager
    // For now, reload full catalog instead of a genre subset
    loadAllBooks();
}

void BookListModel::clear()
{
    beginResetModel();
    m_books.clear();
    endResetModel();
    emit countChanged();
}

void BookListModel::populateBooks(const QList<BookDisplayInfo>& books)
{
    beginResetModel();
    m_books = books;
    endResetModel();
    emit countChanged();
}
