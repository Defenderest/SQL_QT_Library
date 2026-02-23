#ifndef AUTHORDETAILSMODEL_H
#define AUTHORDETAILSMODEL_H

#include <QObject>
#include <QVariantList>
#include "../models/datatypes.h"

class DatabaseManager;

class AuthorDetailsModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(int authorId READ authorId WRITE setAuthorId NOTIFY authorIdChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY detailsChanged)
    Q_PROPERTY(QString firstName READ firstName NOTIFY detailsChanged)
    Q_PROPERTY(QString lastName READ lastName NOTIFY detailsChanged)
    Q_PROPERTY(QString fullName READ fullName NOTIFY detailsChanged)
    Q_PROPERTY(QString nationality READ nationality NOTIFY detailsChanged)
    Q_PROPERTY(QString imagePath READ imagePath NOTIFY detailsChanged)
    Q_PROPERTY(QString biography READ biography NOTIFY detailsChanged)
    Q_PROPERTY(QString birthDate READ birthDate NOTIFY detailsChanged)
    Q_PROPERTY(QVariantList books READ books NOTIFY detailsChanged)

public:
    explicit AuthorDetailsModel(QObject *parent = nullptr);

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    int authorId() const;
    void setAuthorId(int authorId);

    bool loaded() const;
    QString firstName() const;
    QString lastName() const;
    QString fullName() const;
    QString nationality() const;
    QString imagePath() const;
    QString biography() const;
    QString birthDate() const;
    QVariantList books() const;

    Q_INVOKABLE void loadAuthorDetails(int authorId = -1);

signals:
    void dbManagerChanged();
    void authorIdChanged();
    void detailsChanged();
    void errorOccurred(const QString& message);

private:
    void reset();

    DatabaseManager* m_dbManager = nullptr;
    int m_authorId = -1;
    AuthorDetailsInfo m_details;
    QVariantList m_books;
};

#endif // AUTHORDETAILSMODEL_H
