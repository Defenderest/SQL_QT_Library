#include "authordetailsmodel.h"
#include "../core/database.h"

AuthorDetailsModel::AuthorDetailsModel(QObject *parent)
    : QObject(parent)
{
}

DatabaseManager* AuthorDetailsModel::dbManager() const
{
    return m_dbManager;
}

void AuthorDetailsModel::setDbManager(DatabaseManager* dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
    }
}

int AuthorDetailsModel::authorId() const
{
    return m_authorId;
}

void AuthorDetailsModel::setAuthorId(int authorId)
{
    if (m_authorId != authorId) {
        m_authorId = authorId;
        emit authorIdChanged();
    }
}

bool AuthorDetailsModel::loaded() const { return m_details.found; }
QString AuthorDetailsModel::firstName() const { return m_details.firstName; }
QString AuthorDetailsModel::lastName() const { return m_details.lastName; }
QString AuthorDetailsModel::fullName() const { return QString("%1 %2").arg(m_details.firstName, m_details.lastName).trimmed(); }
QString AuthorDetailsModel::nationality() const { return m_details.nationality; }
QString AuthorDetailsModel::imagePath() const { return m_details.imagePath; }
QString AuthorDetailsModel::biography() const { return m_details.biography; }
QString AuthorDetailsModel::birthDate() const { return m_details.birthDate.toString("dd.MM.yyyy"); }
QVariantList AuthorDetailsModel::books() const { return m_books; }

void AuthorDetailsModel::loadAuthorDetails(int authorId)
{
    if (authorId > 0) {
        setAuthorId(authorId);
    }

    if (!m_dbManager || m_authorId <= 0) {
        reset();
        emit detailsChanged();
        return;
    }

    m_details = m_dbManager->getAuthorDetails(m_authorId);
    m_books.clear();

    if (!m_details.found) {
        emit detailsChanged();
        return;
    }

    for (const auto& book : m_details.books) {
        QVariantMap map;
        map["bookId"] = book.bookId;
        map["title"] = book.title;
        map["authors"] = book.authors;
        map["price"] = book.price;
        map["coverImagePath"] = book.coverImagePath;
        map["stockQuantity"] = book.stockQuantity;
        map["genre"] = book.genre;
        m_books.append(map);
    }

    emit detailsChanged();
}

void AuthorDetailsModel::reset()
{
    m_details = AuthorDetailsInfo();
    m_books.clear();
}
