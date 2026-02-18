#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickStyle>
#include <QIcon>
#include <QDebug>
#include <QMessageBox>
#include <QSplashScreen>
#include <QLabel>
#include <QTimer>

#include "database.h"
#include "logindialog.h"

// QML Models
#include "qml_models/appcontext.h"
#include "qml_models/booklistmodel.h"
#include "qml_models/authorlistmodel.h"
#include "qml_models/cartmodel.h"
#include "qml_models/ordersmodel.h"
#include "qml_models/profilemodel.h"
#include "qml_models/theme.h"

int main(int argc, char *argv[])
{
    // Включаем высокое DPI для чёткого отображения
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    // Создаем GUI приложение с поддержкой виджетов (для диалогов)
    QApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/icons/icons/app_icon.png"));
    app.setApplicationName("Bookstore");
    app.setOrganizationName("Patsera_Ihor");
    app.setApplicationVersion("1.0");

    // Показываем Splash Screen сразу, чтобы пользователь видел, что приложение запускается
    QSplashScreen splash(QPixmap(":/images/banner2.jpg").scaled(800, 500, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    QLabel splashLabel(&splash);
    splashLabel.setText("OBSIDIAN.LUXE | BookStore\n\nЗавантаження...");
    splashLabel.setAlignment(Qt::AlignCenter);
    splashLabel.setStyleSheet("QLabel { color: white; font-size: 24px; font-family: 'Inter'; background: transparent; }");
    splashLabel.setGeometry(0, 350, 800, 100);
    splash.show();
    app.processEvents();

    // Подключаемся к базе данных
    splashLabel.setText("OBSIDIAN.LUXE | BookStore\n\nПідключення до бази даних...");
    app.processEvents();

    DatabaseManager dbManager;
    bool connected = dbManager.connectToDatabase(
        "127.0.0.1",
        2112,
        "postgres",
        "postgres",
        "2112"
    );

    if (!connected) {
        splash.finish(nullptr);
        QMessageBox::critical(nullptr, QObject::tr("Помилка підключення до БД"),
                              QObject::tr("Не вдалося підключитися до бази даних.\nДодаток не може продовжити роботу.\n") + dbManager.lastError().text());
        qCritical() << "Database connection failed. Application cannot start.";
        return 1;
    }

    // Автоматическая инициализация и заполнение БД
    splashLabel.setText("OBSIDIAN.LUXE | BookStore\n\nІніціалізація бази даних...");
    app.processEvents();

    if (!dbManager.checkAndInitDatabase()) {
        qWarning() << "Database initialization failed or was partially successful.";
    }

    // Закрываем splash перед показом диалога входа
    splash.finish(nullptr);

    // Показываем диалог входа (пока на виджетах)
    LoginDialog loginDialog(&dbManager);
    int loggedInUserId = -1;

    if (loginDialog.exec() != QDialog::Accepted) {
        return 0;
    }

    loggedInUserId = loginDialog.getLoggedInCustomerId();
    if (loggedInUserId <= 0) {
        QMessageBox::critical(nullptr, QObject::tr("Помилка входу"),
                              QObject::tr("Не вдалося отримати ідентифікатор користувача після входу."));
        qCritical() << "Failed to retrieve valid user ID after login.";
        return 1;
    }

    qDebug() << "User logged in with ID:" << loggedInUserId;

    // Создаем QML модели (лёгкие - просто инициализация)
    AppContext appContext;
    appContext.setDbManager(&dbManager);
    appContext.setCurrentCustomerId(loggedInUserId);

    // Создаем модели, но НЕ загружаем данные сразу - пусть загрузятся при первом открытии страницы
    BookListModel bookModel;
    bookModel.setDbManager(&dbManager);
    // ОТКЛЮЧЕНО: bookModel.loadPopularBooks(); - будет загружено при открытии BooksPage

    BookListModel newArrivalsModel;
    newArrivalsModel.setDbManager(&dbManager);
    // ОТКЛЮЧЕНО: newArrivalsModel.loadNewArrivals(); - загрузим после старта QML

    AuthorListModel authorModel;
    authorModel.setDbManager(&dbManager);
    // ОТКЛЮЧЕНО: authorModel.loadFeaturedAuthors(); - будет загружено при открытии AuthorsPage

    CartModel cartModel;
    cartModel.setDbManager(&dbManager);
    cartModel.setCustomerId(loggedInUserId);

    OrdersModel ordersModel;
    ordersModel.setDbManager(&dbManager);
    ordersModel.setCustomerId(loggedInUserId);
    // ОТКЛЮЧЕНО: ordersModel.loadOrders(); - будет загружено при открытии OrdersPage

    ProfileModel profileModel;
    profileModel.setDbManager(&dbManager);
    profileModel.setCustomerId(loggedInUserId);
    // ОТКЛЮЧЕНО: profileModel.loadProfile(); - будет загружено при открытии ProfilePage

    // Создаем Theme
    Theme theme;

    // Устанавливаем стиль для Qt Quick Controls
    QQuickStyle::setStyle("Fusion");

    // Создаем QML движок
    QQmlApplicationEngine engine;

    // Регистрируем контекстные свойства (доступны во всех QML файлах)
    engine.rootContext()->setContextProperty("Theme", &theme);
    engine.rootContext()->setContextProperty("appContext", &appContext);
    engine.rootContext()->setContextProperty("bookModel", &bookModel);
    engine.rootContext()->setContextProperty("newArrivalsModel", &newArrivalsModel);
    engine.rootContext()->setContextProperty("authorModel", &authorModel);
    engine.rootContext()->setContextProperty("cartModel", &cartModel);
    engine.rootContext()->setContextProperty("ordersModel", &ordersModel);
    engine.rootContext()->setContextProperty("profileModel", &profileModel);

    // Загружаем главный QML файл
    const QUrl url(QStringLiteral("qrc:/main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load QML:" << url;
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    // Выводим ошибки QML
    QObject::connect(&engine, &QQmlApplicationEngine::warnings,
                     [](const QList<QQmlError> &warnings) {
        for (const auto &warning : warnings) {
            qCritical() << "QML Error:" << warning.toString();
        }
    });

    engine.load(url);

    // Подключаем сигналы AppContext к действиям
    QObject::connect(&appContext, &AppContext::navigateToPage,
                     [&engine](const QString& page) {
        qDebug() << "Navigate to page from C++:" << page;
        // Получаем корневой объект QML и меняем страницу
        if (engine.rootObjects().isEmpty()) return;
        QObject *root = engine.rootObjects().first();
        if (root) {
            root->setProperty("currentPage", page);
            // Вызываем функцию навигации с именем страницы
            QMetaObject::invokeMethod(root, "navigateToPage",
                                      Q_ARG(QVariant, page));
        }
    });

    QObject::connect(&appContext, &AppContext::navigateToBookDetailsRequested,
                     [&engine](int bookId) {
        qDebug() << "Navigate to book details:" << bookId;
        // TODO: Implement navigation
    });

    QObject::connect(&appContext, &AppContext::navigateToAuthorDetailsRequested,
                     [&engine](int authorId) {
        qDebug() << "Navigate to author details:" << authorId;
        // TODO: Implement navigation
    });

    QObject::connect(&appContext, &AppContext::checkoutRequested,
                     [&engine]() {
        qDebug() << "Checkout requested";
        // TODO: Show checkout dialog
    });

    QObject::connect(&appContext, &AppContext::logoutRequested,
                     &app, [&app]() {
        qDebug() << "Logout requested";
        app.quit();
    });

    // Загружаем данные для главной страницы ПОСЛЕ запуска QML, чтобы UI появился быстро
    QTimer::singleShot(100, [&]() {
        qDebug() << "Loading initial data for HomePage...";
        newArrivalsModel.loadNewArrivals();
        // profileModel.loadProfile(); // Загрузим при открытии профиля
    });

    return app.exec();
}
