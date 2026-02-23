#include "bookdetailsmodel.h"
#include "../core/database.h"

BookDetailsModel::BookDetailsModel(QObject *parent)
    : QObject(parent)
{
}

DatabaseManager* BookDetailsModel::dbManager() const
{
    return m_dbManager;
}

void BookDetailsModel::setDbManager(DatabaseManager* dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
    }
}

int BookDetailsModel::bookId() const
{
    return m_bookId;
}

void BookDetailsModel::setBookId(int bookId)
{
    if (m_bookId != bookId) {
        m_bookId = bookId;
        emit bookIdChanged();
    }
}

bool BookDetailsModel::loaded() const { return m_details.found; }
QString BookDetailsModel::title() const { return m_details.title; }
QString BookDetailsModel::authors() const { return m_details.authors; }
double BookDetailsModel::price() const { return m_details.price; }
QString BookDetailsModel::coverImagePath() const { return m_details.coverImagePath; }
int BookDetailsModel::stockQuantity() const { return m_details.stockQuantity; }
QString BookDetailsModel::genre() const { return m_details.genre; }
QString BookDetailsModel::description() const { return m_details.description; }
QString BookDetailsModel::language() const { return m_details.language; }
QString BookDetailsModel::publisherName() const { return m_details.publisherName; }
QString BookDetailsModel::publicationDate() const { return m_details.publicationDate.toString("dd.MM.yyyy"); }
QString BookDetailsModel::isbn() const { return m_details.isbn; }
int BookDetailsModel::pageCount() const { return m_details.pageCount; }
double BookDetailsModel::averageRating() const { return m_averageRating; }
QVariantList BookDetailsModel::comments() const { return m_comments; }
QVariantList BookDetailsModel::similarBooks() const { return m_similarBooks; }

void BookDetailsModel::loadBookDetails(int bookId)
{
    if (bookId > 0) {
        setBookId(bookId);
    }

    if (!m_dbManager || m_bookId <= 0) {
        reset();
        emit detailsChanged();
        return;
    }

    m_details = m_dbManager->getBookDetails(m_bookId);
    m_comments.clear();
    m_similarBooks.clear();
    m_averageRating = 0.0;

    if (!m_details.found) {
        emit detailsChanged();
        return;
    }

    int ratingSum = 0;
    for (const auto& comment : m_details.comments) {
        QVariantMap map;
        map["authorName"] = comment.authorName;
        map["commentDate"] = comment.commentDate.toString("dd.MM.yyyy");
        map["rating"] = comment.rating;
        map["commentText"] = comment.commentText;
        m_comments.append(map);
        ratingSum += comment.rating;
    }
    if (!m_details.comments.isEmpty()) {
        m_averageRating = static_cast<double>(ratingSum) / static_cast<double>(m_details.comments.size());
    }

    const QList<BookDisplayInfo> similar = m_dbManager->getSimilarBooks(m_bookId, m_details.genre, 6);
    for (const auto& book : similar) {
        QVariantMap map;
        map["bookId"] = book.bookId;
        map["title"] = book.title;
        map["authors"] = book.authors;
        map["price"] = book.price;
        map["coverImagePath"] = book.coverImagePath;
        map["stockQuantity"] = book.stockQuantity;
        map["genre"] = book.genre;
        m_similarBooks.append(map);
    }

    emit detailsChanged();
}

bool BookDetailsModel::submitComment(int customerId, const QString& commentText, int rating)
{
    if (!m_dbManager || m_bookId <= 0 || customerId <= 0) {
        emit errorOccurred("Invalid data to submit comment");
        return false;
    }
    if (commentText.trimmed().isEmpty() || rating < 1 || rating > 5) {
        emit errorOccurred("Invalid comment text or rating");
        return false;
    }

    const bool ok = m_dbManager->addComment(m_bookId, customerId, commentText.trimmed(), rating);
    if (!ok) {
        emit errorOccurred("Failed to submit comment");
        return false;
    }

    loadBookDetails();
    return true;
}

void BookDetailsModel::reset()
{
    m_details = BookDetailsInfo();
    m_averageRating = 0.0;
    m_comments.clear();
    m_similarBooks.clear();
}
