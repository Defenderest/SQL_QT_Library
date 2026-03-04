#ifndef GEMINICLIENT_H
#define GEMINICLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>

class DatabaseManager;

class GeminiClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString apiKey READ apiKey WRITE setApiKey NOTIFY apiKeyChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit GeminiClient(QObject *parent = nullptr);
    
    QString apiKey() const { return m_apiKey; }
    void setApiKey(const QString& key);
    
    bool isLoading() const { return m_isLoading; }
    
    Q_INVOKABLE void sendMessage(const QString& message, const QString& context = "");
    Q_INVOKABLE void setSystemPrompt(const QString& prompt);
    Q_INVOKABLE void listAvailableModels();

    void setDbManager(DatabaseManager* dbManager);
    
signals:
    void apiKeyChanged();
    void isLoadingChanged();
    void responseReceived(const QString& response);
    void errorOccurred(const QString& error);

private slots:
    void onReplyFinished();

private:
    QJsonArray buildToolsPayload() const;
    QJsonObject executeToolCall(const QString& functionName, const QJsonObject& args) const;
    QJsonObject buildRequestBody(const QJsonArray& conversation, bool allowToolCalls) const;

    QString m_apiKey;
    bool m_isLoading = false;
    QNetworkAccessManager* m_networkManager;
    QString m_systemPrompt;
    DatabaseManager* m_dbManager = nullptr;
    
    static const QString API_URL;
};

#endif // GEMINICLIENT_H
