#ifndef BOOKLISTMODEL_H
#define BOOKLISTMODEL_H

#include <QAbstractListModel>
#include <QList>
#include <QStringList>
#include "../models/datatypes.h"

class DatabaseManager;

class BookListModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(DatabaseManager* dbManager READ dbManager WRITE setDbManager NOTIFY dbManagerChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum BookRoles {
        BookIdRole = Qt::UserRole + 1,
        TitleRole,
        AuthorsRole,
        PriceRole,
        CoverImagePathRole,
        StockQuantityRole,
        GenreRole
    };
    Q_ENUM(BookRoles)

    explicit BookListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    DatabaseManager* dbManager() const;
    void setDbManager(DatabaseManager* dbManager);

    int count() const;

    Q_INVOKABLE void loadAllBooks();
    Q_INVOKABLE void loadPopularBooks();
    Q_INVOKABLE void loadNewArrivals();
    Q_INVOKABLE QStringList getAvailableGenres() const;
    Q_INVOKABLE QStringList getAvailableLanguages() const;
    Q_INVOKABLE void loadFilteredBooks(const QString& genre = QString(),
                                        const QString& language = QString(),
                                        double minPrice = -1,
                                        double maxPrice = -1,
                                        bool inStockOnly = false);
    Q_INVOKABLE void searchBooks(const QString& query);

signals:
    void dbManagerChanged();
    void countChanged();
    void errorOccurred(const QString& message);

private:
    DatabaseManager* m_dbManager = nullptr;
    QList<BookDisplayInfo> m_books;

    void clear();
    void populateBooks(const QList<BookDisplayInfo>& books);
};

#endif // BOOKLISTMODEL_H
