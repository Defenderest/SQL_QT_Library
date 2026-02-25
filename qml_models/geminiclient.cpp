#include "geminiclient.h"
#include "../core/database.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QUrl>
#include <QDebug>

const QString GeminiClient::API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

GeminiClient::GeminiClient(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
}

void GeminiClient::setApiKey(const QString& key)
{
    if (m_apiKey != key) {
        m_apiKey = key;
        emit apiKeyChanged();
    }
}

void GeminiClient::setSystemPrompt(const QString& prompt)
{
    m_systemPrompt = prompt;
}

void GeminiClient::listAvailableModels()
{
    if (m_apiKey.isEmpty()) {
        qDebug() << "❌ API ключ не налаштований!";
        qDebug() << "Встановіть змінну середовища GEMINI_API_KEY або GOOGLE_API_KEY";
        return;
    }
    
    QUrl url("https://generativelanguage.googleapis.com/v1beta/models?key=" + m_apiKey);
    QNetworkRequest request(url);
    
    qDebug() << "📋 Отримання списку доступних моделей...";
    
    QNetworkReply* reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "❌ Помилка отримання моделей:" << reply->errorString();
            reply->deleteLater();
            return;
        }
        
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        
        if (!doc.isObject()) {
            qDebug() << "❌ Неправильна відповідь від сервера";
            reply->deleteLater();
            return;
        }
        
        QJsonObject rootObj = doc.object();
        QJsonArray models = rootObj["models"].toArray();
        
        qDebug() << "\n📚 ДОСТУПНІ МОДЕЛІ GEMINI:";
        qDebug() << "=" + QString(60, '=');
        
        for (const QJsonValue& modelVal : models) {
            QJsonObject model = modelVal.toObject();
            QString name = model["name"].toString();
            QString displayName = model["displayName"].toString();
            QString description = model["description"].toString();
            QString version = model["version"].toString();
            
            // Показуємо тільки gemini моделі
            if (name.contains("gemini")) {
                qDebug() << "\n🤖" << displayName;
                qDebug() << "   Ім'я:" << name;
                if (!description.isEmpty()) {
                    qDebug() << "   Опис:" << description;
                }
                if (!version.isEmpty()) {
                    qDebug() << "   Версія:" << version;
                }
                
                // Показуємо підтримувані методи
                QJsonArray supportedMethods = model["supportedGenerationMethods"].toArray();
                QStringList methods;
                for (const QJsonValue& method : supportedMethods) {
                    methods << method.toString();
                }
                if (!methods.isEmpty()) {
                    qDebug() << "   Методи:" << methods.join(", ");
                }
            }
        }
        
        qDebug() << "\n" + QString(60, '=');
        qDebug() << "💡 РЕКОМЕНДАЦІЯ: Використовуйте модель з generateContent методом";
        qDebug() << "   Наприклад: models/gemini-1.5-flash або models/gemini-1.5-pro\n";
        
        reply->deleteLater();
    });
}

void GeminiClient::sendMessage(const QString& message, const QString& context)
{
    if (m_apiKey.isEmpty()) {
        emit errorOccurred("API ключ не налаштований. Встановіть змінну середовища GEMINI_API_KEY.");
        return;
    }
    
    m_isLoading = true;
    emit isLoadingChanged();
    
    QUrl url(API_URL + "?key=" + m_apiKey);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    // Build request body
    QJsonObject requestBody;
    QJsonArray contents;
    
    // Add system instruction for Gemini 2.5 Flash Preview
    if (!m_systemPrompt.isEmpty()) {
        QJsonObject systemInstruction;
        QJsonArray systemParts;
        QJsonObject systemPart;
        systemPart["text"] = m_systemPrompt;
        systemParts.append(systemPart);
        systemInstruction["parts"] = systemParts;
        requestBody["systemInstruction"] = systemInstruction;
    }
    
    // Build user message with context
    QString fullMessage = message;
    if (!context.isEmpty()) {
        fullMessage = "Контекст: " + context + "\n\nПитання: " + message;
    }
    
    // Add user message
    QJsonObject userContent;
    QJsonArray userParts;
    QJsonObject userPart;
    userPart["text"] = fullMessage;
    userParts.append(userPart);
    userContent["parts"] = userParts;
    userContent["role"] = "user";
    contents.append(userContent);
    
    requestBody["contents"] = contents;
    
    // Generation config - низька температура для точності
    QJsonObject generationConfig;
    generationConfig["temperature"] = 0.1; // Зменшили для точності (було 0.7)
    generationConfig["maxOutputTokens"] = 2048;
    generationConfig["topP"] = 0.9;
    generationConfig["topK"] = 20;
    requestBody["generationConfig"] = generationConfig;
    
    QJsonDocument doc(requestBody);
    QByteArray data = doc.toJson();
    
    QNetworkReply* reply = m_networkManager->post(request, data);
    connect(reply, &QNetworkReply::finished, this, &GeminiClient::onReplyFinished);
}

void GeminiClient::onReplyFinished()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    m_isLoading = false;
    emit isLoadingChanged();
    
    if (reply->error() != QNetworkReply::NoError) {
        QString errorMsg = "Помилка мережі: " + reply->errorString();
        QByteArray errorData = reply->readAll();
        qDebug() << errorMsg;
        qDebug() << "Error response:" << errorData;
        
        // Try to parse error response
        QJsonDocument errorDoc = QJsonDocument::fromJson(errorData);
        if (errorDoc.isObject()) {
            QJsonObject errorObj = errorDoc.object();
            if (errorObj.contains("error")) {
                QString apiError = errorObj["error"].toObject()["message"].toString();
                emit errorOccurred("Помилка API: " + apiError);
                reply->deleteLater();
                return;
            }
        }
        
        emit errorOccurred(errorMsg);
        reply->deleteLater();
        return;
    }
    
    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    
    if (!doc.isObject()) {
        emit errorOccurred("Неправильна відповідь від сервера");
        reply->deleteLater();
        return;
    }
    
    QJsonObject rootObj = doc.object();
    
    // Check for error
    if (rootObj.contains("error")) {
        QJsonObject errorObj = rootObj["error"].toObject();
        QString errorMsg = errorObj["message"].toString();
        qDebug() << "API Error:" << errorMsg;
        emit errorOccurred("Помилка API: " + errorMsg);
        reply->deleteLater();
        return;
    }
    
    // Parse response
    QJsonArray candidates = rootObj["candidates"].toArray();
    if (candidates.isEmpty()) {
        emit errorOccurred("Порожня відповідь від AI");
        reply->deleteLater();
        return;
    }
    
    QJsonObject candidate = candidates.first().toObject();
    QJsonObject content = candidate["content"].toObject();
    QJsonArray parts = content["parts"].toArray();
    
    if (parts.isEmpty()) {
        emit errorOccurred("Порожня відповідь від AI");
        reply->deleteLater();
        return;
    }
    
    QString responseText = parts.first().toObject()["text"].toString();
    qDebug() << "📨 Отримано відповідь від AI (довжина:" << responseText.length() << "символів):";
    qDebug() << responseText.left(200) << "...";
    emit responseReceived(responseText);
    
    reply->deleteLater();
}
