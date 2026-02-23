#include "authorlistmodel.h"
#include "../core/database.h"
#include <QDebug>

AuthorListModel::AuthorListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int AuthorListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_authors.count();
}

QVariant AuthorListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_authors.count())
        return QVariant();

    const AuthorDisplayInfo &author = m_authors.at(index.row());

    switch (role) {
    case AuthorIdRole:
        return author.authorId;
    case FirstNameRole:
        return author.firstName;
    case LastNameRole:
        return author.lastName;
    case NationalityRole:
        return author.nationality;
    case ImagePathRole:
        return author.imagePath;
    case FullNameRole:
        return author.firstName + " " + author.lastName;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> AuthorListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[AuthorIdRole] = "authorId";
    roles[FirstNameRole] = "firstName";
    roles[LastNameRole] = "lastName";
    roles[NationalityRole] = "nationality";
    roles[ImagePathRole] = "imagePath";
    roles[FullNameRole] = "fullName";
    return roles;
}

DatabaseManager* AuthorListModel::dbManager() const
{
    return m_dbManager;
}

void AuthorListModel::setDbManager(DatabaseManager* dbManager)
{
    if (m_dbManager != dbManager) {
        m_dbManager = dbManager;
        emit dbManagerChanged();
    }
}

int AuthorListModel::count() const
{
    return m_authors.count();
}

void AuthorListModel::loadAllAuthors()
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager not set");
        return;
    }

    beginResetModel();
    m_authors = m_dbManager->getAllAuthorsForDisplay();
    endResetModel();
    emit countChanged();
}

void AuthorListModel::loadFeaturedAuthors(int limit)
{
    if (!m_dbManager) {
        emit errorOccurred("Database manager not set");
        return;
    }

    beginResetModel();
    QList<AuthorDisplayInfo> allAuthors = m_dbManager->getAllAuthorsForDisplay();
    m_authors.clear();
    int count = qMin(limit, allAuthors.count());
    for (int i = 0; i < count; ++i) {
        m_authors.append(allAuthors[i]);
    }
    endResetModel();
    emit countChanged();
}

void AuthorListModel::searchAuthors(const QString& query)
{
    if (!m_dbManager || query.isEmpty()) {
        loadAllAuthors();
        return;
    }

    // TODO: Implement search in DatabaseManager
    loadAllAuthors();
}
