#ifndef BOOKFILTERMANAGER_H
#define BOOKFILTERMANAGER_H

#include <QObject>
#include <QString>
#include <QList>
#include "datatypes.h" // Для BookDisplayInfo та BookFilterCriteria

class DatabaseManager; // Forward declaration

class BookFilterManager : public QObject
{
    Q_OBJECT
public:
    explicit BookFilterManager(DatabaseManager *dbManager, QObject *parent = nullptr);

    // Методи для встановлення критеріїв
    void setGenreFilter(const QString &genre);
    void setPriceRangeFilter(double minPrice, double maxPrice);
    void resetFilters();

    // Метод для отримання поточних критеріїв
    BookFilterCriteria getCurrentCriteria() const;

    // Метод для отримання відфільтрованого списку книг
    QList<BookDisplayInfo> getFilteredBooks() const;

signals:
    // Сигнал, що випромінюється при зміні фільтрів (після застосування)
    // Цей сигнал може бути корисним, якщо інші частини програми
    // захочуть реагувати на зміну фільтрів. Наразі він не використовується
    // безпосередньо в MainWindow, оскільки оновлення відбувається явно.
    // void filtersApplied(); // Закоментовано, оскільки не використовується

private:
    DatabaseManager *m_dbManager; // Вказівник на менеджер БД (не володіє ним)
    BookFilterCriteria m_currentCriteria;
};

#endif // BOOKFILTERMANAGER_H
