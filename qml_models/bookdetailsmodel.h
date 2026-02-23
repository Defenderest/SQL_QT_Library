#ifndef BOOKDETAILSMODEL_H
#define BOOKDETAILSMODEL_H

#include <QObject>
#include <QVariantList>
#include "../models/datatypes.h"

class DatabaseManager;

class BookDetailsModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(int bookId READ bookId WRITE setBookId NOTIFY bookIdChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY detailsChanged)
    Q_PROPERTY(QString title READ title NOTIFY detailsChanged)
    Q_PROPERTY(QString authors READ authors NOTIFY detailsChanged)
    Q_PROPERTY(double price READ price NOTIFY detailsChanged)
    Q_PROPERTY(QString coverImagePath READ coverImagePath NOTIFY detailsChanged)
    Q_PROPERTY(int stockQuantity READ stockQuantity NOTIFY detailsChanged)
    Q_PROPERTY(QString genre READ genre NOTIFY detailsChanged)
    Q_PROPERTY(QString description READ description NOTIFY detailsChanged)
    Q_PROPERTY(QString language READ language NOTIFY detailsChanged)
    Q_PROPERTY(QString publisherName READ publisherName NOTIFY detailsChanged)
    Q_PROPERTY(QString publicationDate READ publicationDate NOTIFY detailsChanged)
    Q_PROPERTY(QString isbn READ isbn NOTIFY detailsChanged)
    Q_PROPERTY(int pageCount READ pageCount NOTIFY detailsChanged)
    Q_PROPERTY(double averageRating READ averageRating NOTIFY detailsChanged)
    Q_PROPERTY(QVariantList comments READ comments NOTIFY detailsChanged)
    Q_PROPERTY(QVariantList similarBooks READ similarBooks NOTIFY detailsChanged)

public:
    explicit BookDetailsModel(QObject *parent = nullptr);

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    int bookId() const;
    void setBookId(int bookId);

    bool loaded() const;
    QString title() const;
    QString authors() const;
    double price() const;
    QString coverImagePath() const;
    int stockQuantity() const;
    QString genre() const;
    QString description() const;
    QString language() const;
    QString publisherName() const;
    QString publicationDate() const;
    QString isbn() const;
    int pageCount() const;
    double averageRating() const;
    QVariantList comments() const;
    QVariantList similarBooks() const;

    Q_INVOKABLE void loadBookDetails(int bookId = -1);
    Q_INVOKABLE bool submitComment(int customerId, const QString& commentText, int rating);

signals:
    void dbManagerChanged();
    void bookIdChanged();
    void detailsChanged();
    void errorOccurred(const QString& message);

private:
    void reset();

    DatabaseManager* m_dbManager = nullptr;
    int m_bookId = -1;
    BookDetailsInfo m_details;
    double m_averageRating = 0.0;
    QVariantList m_comments;
    QVariantList m_similarBooks;
};

#endif // BOOKDETAILSMODEL_H
