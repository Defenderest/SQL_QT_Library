#ifndef GEMINICLIENT_H
#define GEMINICLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>

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
    
    // Build comprehensive context from database
    QString buildBooksContext();

signals:
    void apiKeyChanged();
    void isLoadingChanged();
    void responseReceived(const QString& response);
    void errorOccurred(const QString& error);

private slots:
    void onReplyFinished();

private:
    QString m_apiKey;
    bool m_isLoading = false;
    QNetworkAccessManager* m_networkManager;
    QString m_systemPrompt;
    
    static const QString API_URL;
};

#endif // GEMINICLIENT_H