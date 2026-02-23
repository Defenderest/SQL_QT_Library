#ifndef AUTHORLISTMODEL_H
#define AUTHORLISTMODEL_H

#include <QAbstractListModel>
#include <QList>
#include "../models/datatypes.h"

class DatabaseManager;

class AuthorListModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum AuthorRoles {
        AuthorIdRole = Qt::UserRole + 1,
        FirstNameRole,
        LastNameRole,
        NationalityRole,
        ImagePathRole,
        FullNameRole
    };
    Q_ENUM(AuthorRoles)

    explicit AuthorListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    int count() const;

    Q_INVOKABLE void loadAllAuthors();
    Q_INVOKABLE void loadFeaturedAuthors(int limit = 8);
    Q_INVOKABLE void searchAuthors(const QString& query);

signals:
    void dbManagerChanged();
    void countChanged();
    void errorOccurred(const QString& message);

private:
    DatabaseManager* m_dbManager = nullptr;
    QList<AuthorDisplayInfo> m_authors;
};

#endif // AUTHORLISTMODEL_H
