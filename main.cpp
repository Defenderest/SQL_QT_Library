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
#include <QByteArray>

#include "database.h"

// QML Models
#include "qml_models/appcontext.h"
#include "qml_models/booklistmodel.h"
#include "qml_models/bookdetailsmodel.h"
#include "qml_models/authorlistmodel.h"
#include "qml_models/authordetailsmodel.h"
#include "qml_models/cartmodel.h"
#include "qml_models/ordersmodel.h"
#include "qml_models/profilemodel.h"
#include "qml_models/adminmodel.h"
#include "qml_models/theme.h"
#include "qml_models/geminiclient.h"

int main(int argc, char *argv[])
{
    QByteArray chromiumFlags = qgetenv("QTWEBENGINE_CHROMIUM_FLAGS");
    if (!chromiumFlags.isEmpty()) {
        chromiumFlags += ' ';
    }
    chromiumFlags += "--ignore-gpu-blocklist "
                     "--enable-gpu-rasterization "
                     "--enable-zero-copy "
                     "--num-raster-threads=4 "
                     "--disable-background-timer-throttling "
                     "--disable-renderer-backgrounding "
                     "--disable-backgrounding-occluded-windows";
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", chromiumFlags);

    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    QApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/icons/icons/app_icon.png"));
    app.setApplicationName("Bookstore");
    app.setOrganizationName("Patsera_Ihor");
    app.setApplicationVersion("1.0");

    QSplashScreen splash(QPixmap(":/images/banner2.jpg").scaled(800, 500, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    QLabel splashLabel(&splash);
    splashLabel.setText("OBSIDIAN.LUXE | BookStore\n\nР—Р°РІР°РЅС‚Р°Р¶РµРЅРЅСЏ...");
    splashLabel.setAlignment(Qt::AlignCenter);
    splashLabel.setStyleSheet("QLabel { color: white; font-size: 24px; font-family: 'Inter'; background: transparent; }");
    splashLabel.setGeometry(0, 350, 800, 100);
    splash.show();
    app.processEvents();

    // РџРѕРґРєР»СЋС‡Р°РµРјСЃСЏ Рє Р±Р°Р·Рµ РґР°РЅРЅС‹С…
    splashLabel.setText("Library");
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
        QMessageBox::critical(nullptr, QObject::tr("РџРѕРјРёР»РєР° РїС–РґРєР»СЋС‡РµРЅРЅСЏ РґРѕ Р‘Р”"),
                              QObject::tr("РќРµ РІРґР°Р»РѕСЃСЏ РїС–РґРєР»СЋС‡РёС‚РёСЃСЏ РґРѕ Р±Р°Р·Рё РґР°РЅРёС….\nР”РѕРґР°С‚РѕРє РЅРµ РјРѕР¶Рµ РїСЂРѕРґРѕРІР¶РёС‚Рё СЂРѕР±РѕС‚Сѓ.\n") + dbManager.lastError().text());
        qCritical() << "Database connection failed. Application cannot start.";
        return 1;
    }

    // РђРІС‚РѕРјР°С‚РёС‡РµСЃРєР°СЏ РёРЅРёС†РёР°Р»РёР·Р°С†РёСЏ Рё Р·Р°РїРѕР»РЅРµРЅРёРµ Р‘Р”
    splashLabel.setText("OLibrary");
    app.processEvents();

    if (!dbManager.checkAndInitDatabase()) {
        qWarning() << "Database initialization failed or was partially successful.";
    }

    // Закриваємо splash та запускаємо застосунок у гостьовому режимі
    splash.finish(nullptr);

    int loggedInUserId = -1;
    const bool loggedInIsAdmin = false;
    qDebug() << "Application started in guest mode.";

    // РЎРѕР·РґР°РµРј QML РјРѕРґРµР»Рё (Р»С‘РіРєРёРµ - РїСЂРѕСЃС‚Рѕ РёРЅРёС†РёР°Р»РёР·Р°С†РёСЏ)
    AppContext appContext;
    appContext.setDbManager(&dbManager);
    appContext.setCurrentCustomerId(loggedInUserId);
    appContext.setIsAdmin(loggedInIsAdmin);

    // РЎРѕР·РґР°РµРј РјРѕРґРµР»Рё, РЅРѕ РќР• Р·Р°РіСЂСѓР¶Р°РµРј РґР°РЅРЅС‹Рµ СЃСЂР°Р·Сѓ - РїСѓСЃС‚СЊ Р·Р°РіСЂСѓР·СЏС‚СЃСЏ РїСЂРё РїРµСЂРІРѕРј РѕС‚РєСЂС‹С‚РёРё СЃС‚СЂР°РЅРёС†С‹
    BookListModel bookModel;
    bookModel.setDbManager(&dbManager);
    // РћРўРљР›Р®Р§Р•РќРћ: bookModel.loadPopularBooks(); - Р±СѓРґРµС‚ Р·Р°РіСЂСѓР¶РµРЅРѕ РїСЂРё РѕС‚РєСЂС‹С‚РёРё BooksPage

    BookListModel newArrivalsModel;
    newArrivalsModel.setDbManager(&dbManager);

    BookDetailsModel bookDetailsModel;
    bookDetailsModel.setDbManager(&dbManager);
    // РћРўРљР›Р®Р§Р•РќРћ: newArrivalsModel.loadNewArrivals(); - Р·Р°РіСЂСѓР·РёРј РїРѕСЃР»Рµ СЃС‚Р°СЂС‚Р° QML

    AuthorListModel authorModel;
    authorModel.setDbManager(&dbManager);

    AuthorDetailsModel authorDetailsModel;
    authorDetailsModel.setDbManager(&dbManager);
    // РћРўРљР›Р®Р§Р•РќРћ: authorModel.loadFeaturedAuthors(); - Р±СѓРґРµС‚ Р·Р°РіСЂСѓР¶РµРЅРѕ РїСЂРё РѕС‚РєСЂС‹С‚РёРё AuthorsPage

    CartModel cartModel;
    cartModel.setDbManager(&dbManager);
    cartModel.setCustomerId(loggedInUserId);
    const auto readLiqPayEnv = [](const char* primaryName,
                                  const char* sandboxName,
                                  const char* legacyName) {
        QString value = qEnvironmentVariable(primaryName).trimmed();
        if (!value.isEmpty()) {
            return value;
        }
        value = qEnvironmentVariable(sandboxName).trimmed();
        if (!value.isEmpty()) {
            return value;
        }
        return qEnvironmentVariable(legacyName).trimmed();
    };

    const QString liqPayPublicKey = readLiqPayEnv("LIQPAY_PUBLIC_KEY", "LIQPAY_SANDBOX_PUBLIC_KEY", "PUBLIC_KEY");
    const QString liqPayPrivateKey = readLiqPayEnv("LIQPAY_PRIVATE_KEY", "LIQPAY_SANDBOX_PRIVATE_KEY", "PRIVATE_KEY");

    cartModel.setLiqPayPublicKey(liqPayPublicKey);
    cartModel.setLiqPayPrivateKey(liqPayPrivateKey);
    if (liqPayPublicKey.isEmpty() || liqPayPrivateKey.isEmpty()) {
        qWarning() << "LiqPay keys are not set in process environment."
                   << "Supported variables: LIQPAY_PUBLIC_KEY / LIQPAY_PRIVATE_KEY"
                   << "or LIQPAY_SANDBOX_PUBLIC_KEY / LIQPAY_SANDBOX_PRIVATE_KEY"
                   << "or PUBLIC_KEY / PRIVATE_KEY.";
    }

    OrdersModel ordersModel;
    ordersModel.setDbManager(&dbManager);
    ordersModel.setCustomerId(loggedInUserId);
    // РћРўРљР›Р®Р§Р•РќРћ: ordersModel.loadOrders(); - Р±СѓРґРµС‚ Р·Р°РіСЂСѓР¶РµРЅРѕ РїСЂРё РѕС‚РєСЂС‹С‚РёРё OrdersPage

    ProfileModel profileModel;
    profileModel.setDbManager(&dbManager);
    profileModel.setCustomerId(loggedInUserId);

    AdminModel adminModel;
    adminModel.setDbManager(&dbManager);
    // РћРўРљР›Р®Р§Р•РќРћ: profileModel.loadProfile(); - Р±СѓРґРµС‚ Р·Р°РіСЂСѓР¶РµРЅРѕ РїСЂРё РѕС‚РєСЂС‹С‚РёРё ProfilePage

    // Создаем Gemini AI клиент
    GeminiClient geminiClient;
    QString geminiApiKey = qEnvironmentVariable("GEMINI_API_KEY");
    if (geminiApiKey.isEmpty()) {
        geminiApiKey = qEnvironmentVariable("GOOGLE_API_KEY");
    }
    geminiClient.setApiKey(geminiApiKey);
    if (geminiApiKey.isEmpty()) {
        qWarning() << "GEMINI_API_KEY not set. AI chat will not work.";
    } else {
        // Виводимо список доступних моделей
        QTimer::singleShot(1000, [&geminiClient]() {
            geminiClient.listAvailableModels();
        });
    }

    // РЎРѕР·РґР°РµРј Theme
    Theme theme;

    // РЈСЃС‚Р°РЅР°РІР»РёРІР°РµРј СЃС‚РёР»СЊ РґР»СЏ Qt Quick Controls
    QQuickStyle::setStyle("Fusion");

    // РЎРѕР·РґР°РµРј QML РґРІРёР¶РѕРє
    QQmlApplicationEngine engine;

    // Р РµРіРёСЃС‚СЂРёСЂСѓРµРј РєРѕРЅС‚РµРєСЃС‚РЅС‹Рµ СЃРІРѕР№СЃС‚РІР° (РґРѕСЃС‚СѓРїРЅС‹ РІРѕ РІСЃРµС… QML С„Р°Р№Р»Р°С…)
engine.rootContext()->setContextProperty("Theme", &theme);
    engine.rootContext()->setContextProperty("appContext", &appContext);
    engine.rootContext()->setContextProperty("bookModel", &bookModel);
    engine.rootContext()->setContextProperty("newArrivalsModel", &newArrivalsModel);
    engine.rootContext()->setContextProperty("bookDetailsModel", &bookDetailsModel);
    engine.rootContext()->setContextProperty("authorModel", &authorModel);
    engine.rootContext()->setContextProperty("authorDetailsModel", &authorDetailsModel);
    engine.rootContext()->setContextProperty("cartModel", &cartModel);
    engine.rootContext()->setContextProperty("ordersModel", &ordersModel);
    engine.rootContext()->setContextProperty("profileModel", &profileModel);
    engine.rootContext()->setContextProperty("adminModel", &adminModel);
    engine.rootContext()->setContextProperty("geminiClient", &geminiClient);

    // Р—Р°РіСЂСѓР¶Р°РµРј РіР»Р°РІРЅС‹Р№ QML С„Р°Р№Р»
    const QUrl url(QStringLiteral("qrc:/main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load QML:" << url;
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    // Р’С‹РІРѕРґРёРј РѕС€РёР±РєРё QML
    QObject::connect(&engine, &QQmlApplicationEngine::warnings,
                     [](const QList<QQmlError> &warnings) {
        for (const auto &warning : warnings) {
            qCritical() << "QML Error:" << warning.toString();
        }
    });

    engine.load(url);

    // РџРѕРґРєР»СЋС‡Р°РµРј СЃРёРіРЅР°Р»С‹ AppContext Рє РґРµР№СЃС‚РІРёСЏРј
    QObject::connect(&appContext, &AppContext::navigateToPage,
                     [&engine](const QString& page) {
        qDebug() << "Navigate to page from C++:" << page;
        // РџРѕР»СѓС‡Р°РµРј РєРѕСЂРЅРµРІРѕР№ РѕР±СЉРµРєС‚ QML Рё РјРµРЅСЏРµРј СЃС‚СЂР°РЅРёС†Сѓ
        if (engine.rootObjects().isEmpty()) return;
        QObject *root = engine.rootObjects().first();
        if (root) {
            root->setProperty("currentPage", page);
            // Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ РЅР°РІРёРіР°С†РёРё СЃ РёРјРµРЅРµРј СЃС‚СЂР°РЅРёС†С‹
            QMetaObject::invokeMethod(root, "navigateToPage",
                                      Q_ARG(QVariant, page));
        }
    });

    QObject::connect(&appContext, &AppContext::navigateToBookDetailsRequested,
                     [&engine](int bookId) {
        qDebug() << "Navigate to book details:" << bookId;
        if (engine.rootObjects().isEmpty()) return;
        QObject *root = engine.rootObjects().first();
        if (root) {
            root->setProperty("selectedBookId", bookId);
            root->setProperty("currentPage", "bookDetails");
            QMetaObject::invokeMethod(root, "navigateToPage",
                                      Q_ARG(QVariant, "bookDetails"));
        }
    });

    QObject::connect(&appContext, &AppContext::navigateToAuthorDetailsRequested,
                     [&engine](int authorId) {
        qDebug() << "Navigate to author details:" << authorId;
        if (engine.rootObjects().isEmpty()) return;
        QObject *root = engine.rootObjects().first();
        if (root) {
            root->setProperty("selectedAuthorId", authorId);
            root->setProperty("currentPage", "authorDetails");
            QMetaObject::invokeMethod(root, "navigateToPage",
                                      Q_ARG(QVariant, "authorDetails"));
        }
    });

    QObject::connect(&appContext, &AppContext::checkoutRequested,
                     [&engine]() {
        qDebug() << "Checkout requested";
        // TODO: Show checkout dialog
    });

    QObject::connect(&appContext, &AppContext::loginDialogRequested,
                     [&engine]() {
        if (!engine.rootObjects().isEmpty()) {
            QObject *rootObj = engine.rootObjects().first();
            if (rootObj) {
                rootObj->setProperty("currentPage", "profile");
                QMetaObject::invokeMethod(rootObj, "navigateToPage", Q_ARG(QVariant, "profile"));
            }
        }
    });

    QObject::connect(&appContext, &AppContext::loginRequested,
                     [&appContext, &cartModel, &ordersModel, &profileModel, &engine]() {
        const int userId = appContext.currentCustomerId();
        if (userId <= 0) {
            return;
        }

        cartModel.setCustomerId(userId);
        ordersModel.setCustomerId(userId);
        profileModel.setCustomerId(userId);

        cartModel.loadCart();
        ordersModel.loadOrders();
        profileModel.loadProfile();

        if (!engine.rootObjects().isEmpty()) {
            QObject *rootObj = engine.rootObjects().first();
            if (rootObj) {
                rootObj->setProperty("currentPage", "profile");
                QMetaObject::invokeMethod(rootObj, "navigateToPage", Q_ARG(QVariant, "profile"));
            }
        }
    });

    QObject::connect(&appContext, &AppContext::logoutRequested,
                     [&appContext, &cartModel, &ordersModel, &profileModel, &engine]() {
        qDebug() << "Logout requested";
        cartModel.setCustomerId(-1);
        ordersModel.setCustomerId(-1);
        profileModel.setCustomerId(-1);
        cartModel.loadCart();
        ordersModel.loadOrders();

        appContext.navigateTo("home");

        if (!engine.rootObjects().isEmpty()) {
            QObject *rootObj = engine.rootObjects().first();
            if (rootObj) {
                rootObj->setProperty("currentPage", "home");
                QMetaObject::invokeMethod(rootObj, "navigateToPage", Q_ARG(QVariant, "home"));
            }
        }
    });

    // Р—Р°РіСЂСѓР¶Р°РµРј РґР°РЅРЅС‹Рµ РґР»СЏ РіР»Р°РІРЅРѕР№ СЃС‚СЂР°РЅРёС†С‹ РџРћРЎР›Р• Р·Р°РїСѓСЃРєР° QML, С‡С‚РѕР±С‹ UI РїРѕСЏРІРёР»СЃСЏ Р±С‹СЃС‚СЂРѕ
    QTimer::singleShot(350, [&]() {
        qDebug() << "Loading initial data for HomePage...";
        newArrivalsModel.loadNewArrivals();
        // profileModel.loadProfile(); // Р—Р°РіСЂСѓР·РёРј РїСЂРё РѕС‚РєСЂС‹С‚РёРё РїСЂРѕС„РёР»СЏ
    });

    return app.exec();
}

