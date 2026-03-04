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
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>
#include <QStringList>

#if __has_include(<QtWebEngineQuick/qtwebenginequickglobal.h>)
#include <QtWebEngineQuick/qtwebenginequickglobal.h>
#elif __has_include(<QtWebEngineQuick/QtWebEngineQuick>)
#include <QtWebEngineQuick/QtWebEngineQuick>
#endif

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
    if (chromiumFlags.trimmed().isEmpty()) {
        chromiumFlags = "--disable-background-timer-throttling "
                        "--disable-renderer-backgrounding "
                        "--disable-backgrounding-occluded-windows";
    }
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", chromiumFlags);

    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    QApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/icons/icons/app_icon.png"));
    app.setApplicationName("Library");
    app.setOrganizationName("Patsera_Ihor");
    app.setApplicationVersion("1.0");

    QtWebEngineQuick::initialize();

    const auto normalizeSecretValue = [](const QString& rawValue) {
        QString value = rawValue.trimmed();
        if (value.length() >= 2) {
            const QChar first = value.front();
            const QChar last = value.back();
            if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
                value = value.mid(1, value.length() - 2).trimmed();
            }
        }
        return value;
    };

    const auto setEnvFromCliArg = [&](const QString& prefix, const char* envName) {
        const QStringList args = QCoreApplication::arguments();
        for (const QString& arg : args) {
            if (arg.startsWith(prefix)) {
                const QString value = normalizeSecretValue(arg.mid(prefix.length()));
                if (!value.isEmpty()) {
                    qputenv(envName, value.toUtf8());
                    return true;
                }
            }
        }
        return false;
    };

    setEnvFromCliArg("--liqpay-public-key=", "LIQPAY_PUBLIC_KEY");
    setEnvFromCliArg("--liqpay-private-key=", "LIQPAY_PRIVATE_KEY");

    const auto loadDotEnvFile = [&](const QString& filePath) {
        QFile file(filePath);
        if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            return false;
        }

        QTextStream stream(&file);
        bool loadedAny = false;
        int lineNumber = 0;
        while (!stream.atEnd()) {
            QString line = stream.readLine();
            ++lineNumber;

            if (lineNumber == 1 && !line.isEmpty() && line.at(0) == QChar(0xFEFF)) {
                line.remove(0, 1);
            }

            line = line.trimmed();
            if (line.isEmpty() || line.startsWith('#')) {
                continue;
            }

            if (line.startsWith("export ")) {
                line = line.mid(7).trimmed();
            }

            const int separatorIndex = line.indexOf('=');
            if (separatorIndex <= 0) {
                continue;
            }

            const QString key = line.left(separatorIndex).trimmed();
            if (key.isEmpty()) {
                continue;
            }

            const QString value = normalizeSecretValue(line.mid(separatorIndex + 1));
            if (value.isEmpty()) {
                continue;
            }

            const QByteArray keyBytes = key.toUtf8();
            if (qEnvironmentVariableIsSet(keyBytes.constData()) &&
                !qEnvironmentVariable(keyBytes.constData()).trimmed().isEmpty()) {
                continue;
            }

            qputenv(keyBytes, value.toUtf8());
            loadedAny = true;
        }

        return loadedAny;
    };

    QStringList dotEnvCandidates;
    dotEnvCandidates << QDir::current().filePath(".env");
    dotEnvCandidates << QDir(QCoreApplication::applicationDirPath()).filePath(".env");
    dotEnvCandidates << QFileInfo(QDir(QCoreApplication::applicationDirPath()).filePath("../.env")).absoluteFilePath();
    for (const QString& candidate : dotEnvCandidates) {
        loadDotEnvFile(candidate);
    }

    const auto readFirstEnvOrDefault = [&](const QStringList& names, const QString& fallback = QString()) {
        for (const QString& name : names) {
            const QByteArray key = name.toUtf8();
            const QString value = normalizeSecretValue(qEnvironmentVariable(key.constData()));
            if (!value.isEmpty()) {
                return value;
            }
        }
        return fallback;
    };

    const auto readEnvIntOrDefault = [&](const QStringList& names, int fallback) {
        for (const QString& name : names) {
            const QByteArray key = name.toUtf8();
            const QString value = normalizeSecretValue(qEnvironmentVariable(key.constData()));
            if (value.isEmpty()) {
                continue;
            }

            bool ok = false;
            const int parsed = value.toInt(&ok);
            if (ok && parsed > 0) {
                return parsed;
            }
        }
        return fallback;
    };

    const QString dbHost = readFirstEnvOrDefault({QStringLiteral("DB_HOST"), QStringLiteral("PGHOST")});
    const int dbPort = readEnvIntOrDefault({QStringLiteral("DB_PORT"), QStringLiteral("PGPORT")}, -1);
    const QString dbName = readFirstEnvOrDefault({QStringLiteral("DB_NAME"), QStringLiteral("PGDATABASE")});
    const QString dbUser = readFirstEnvOrDefault({QStringLiteral("DB_USER"), QStringLiteral("PGUSER")});
    const QString dbPassword = readFirstEnvOrDefault({QStringLiteral("DB_PASSWORD"), QStringLiteral("PGPASSWORD")});

    QStringList missingDbVars;
    if (dbHost.isEmpty()) {
        missingDbVars << QStringLiteral("DB_HOST or PGHOST");
    }
    if (dbPort <= 0) {
        missingDbVars << QStringLiteral("DB_PORT or PGPORT");
    }
    if (dbName.isEmpty()) {
        missingDbVars << QStringLiteral("DB_NAME or PGDATABASE");
    }
    if (dbUser.isEmpty()) {
        missingDbVars << QStringLiteral("DB_USER or PGUSER");
    }
    if (dbPassword.isEmpty()) {
        missingDbVars << QStringLiteral("DB_PASSWORD or PGPASSWORD");
    }

    if (!missingDbVars.isEmpty()) {
        const QString missingMessage = QStringLiteral("Missing database configuration: %1")
                                           .arg(missingDbVars.join(QStringLiteral(", ")));
        qCritical() << missingMessage;
        QMessageBox::critical(nullptr,
                              QObject::tr("Database configuration error"),
                              missingMessage + "\n\nSet these values via environment variables or .env file.");
        return 1;
    }

    QSplashScreen splash(QPixmap(":/images/banner2.jpg").scaled(800, 500, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    QLabel splashLabel(&splash);
    splashLabel.setText("Library\n\nLoading...");
    splashLabel.setAlignment(Qt::AlignCenter);
    splashLabel.setStyleSheet("QLabel { color: white; font-size: 24px; font-family: 'Inter'; background: transparent; }");
    splashLabel.setGeometry(0, 350, 800, 100);
    splash.show();
    app.processEvents();

    // РџРѕРґРєР»СЋС‡Р°РµРјСЃСЏ Рє Р±Р°Р·Рµ РґР°РЅРЅС‹С…
    splashLabel.setText("Connecting to database...");
    app.processEvents();

    DatabaseManager dbManager;
    bool connected = dbManager.connectToDatabase(
        dbHost,
        dbPort,
        dbName,
        dbUser,
        dbPassword
    );

    if (!connected) {
        splash.finish(nullptr);
        QMessageBox::critical(nullptr, QObject::tr("РџРѕРјРёР»РєР° РїС–РґРєР»СЋС‡РµРЅРЅСЏ РґРѕ Р‘Р”"),
                              QObject::tr("РќРµ РІРґР°Р»РѕСЃСЏ РїС–РґРєР»СЋС‡РёС‚РёСЃСЏ РґРѕ Р±Р°Р·Рё РґР°РЅРёС….\nР”РѕРґР°С‚РѕРє РЅРµ РјРѕР¶Рµ РїСЂРѕРґРѕРІР¶РёС‚Рё СЂРѕР±РѕС‚Сѓ.\n") + dbManager.lastError().text());
        qCritical() << "Database connection failed. Application cannot start.";
        return 1;
    }

    // РђРІС‚РѕРјР°С‚РёС‡РµСЃРєР°СЏ РёРЅРёС†РёР°Р»РёР·Р°С†РёСЏ Рё Р·Р°РїРѕР»РЅРµРЅРёРµ Р‘Р”
    splashLabel.setText("Initializing database...");
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
    struct EnvValueResult {
        QString value;
        QString source;
    };

    const auto readEnvValue = [&](const QStringList& names) {
        EnvValueResult result;
        for (const QString& name : names) {
            const QByteArray nameBytes = name.toUtf8();
            const QString value = normalizeSecretValue(qEnvironmentVariable(nameBytes.constData()));
            if (!value.isEmpty()) {
                result.value = value;
                result.source = name;
                return result;
            }
        }
        return result;
    };

    const QStringList liqPayPublicVarNames = {
        QStringLiteral("LIQPAY_PUBLIC_KEY"),
        QStringLiteral("LIQPAY_SANDBOX_PUBLIC_KEY"),
        QStringLiteral("LIQPAY_PUBLIC"),
        QStringLiteral("LIQPAY_SANDBOX_PUBLIC"),
        QStringLiteral("LIQPAY_PUBLICKEY"),
        QStringLiteral("PUBLIC_KEY")
    };
    const QStringList liqPayPrivateVarNames = {
        QStringLiteral("LIQPAY_PRIVATE_KEY"),
        QStringLiteral("LIQPAY_SANDBOX_PRIVATE_KEY"),
        QStringLiteral("LIQPAY_PRIVATE"),
        QStringLiteral("LIQPAY_SANDBOX_PRIVATE"),
        QStringLiteral("LIQPAY_PRIVATEKEY"),
        QStringLiteral("PRIVATE_KEY")
    };

    const EnvValueResult liqPayPublic = readEnvValue(liqPayPublicVarNames);
    const EnvValueResult liqPayPrivate = readEnvValue(liqPayPrivateVarNames);

    const QString liqPayPublicKey = liqPayPublic.value;
    const QString liqPayPrivateKey = liqPayPrivate.value;

    cartModel.setLiqPayPublicKey(liqPayPublicKey);
    cartModel.setLiqPayPrivateKey(liqPayPrivateKey);
    if (liqPayPublicKey.isEmpty() || liqPayPrivateKey.isEmpty()) {
        qWarning() << "LiqPay keys are not set in process environment."
                   << "Supported variables: LIQPAY_PUBLIC_KEY / LIQPAY_PRIVATE_KEY"
                   << "or LIQPAY_SANDBOX_PUBLIC_KEY / LIQPAY_SANDBOX_PRIVATE_KEY"
                   << "or LIQPAY_PUBLIC / LIQPAY_PRIVATE"
                   << "or PUBLIC_KEY / PRIVATE_KEY"
                   << "or CLI args --liqpay-public-key / --liqpay-private-key"
                   << "or .env file in app/current directory.";
    } else {
        qInfo() << "LiqPay keys loaded from" << liqPayPublic.source << "and" << liqPayPrivate.source;
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
    geminiClient.setDbManager(&dbManager);
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

