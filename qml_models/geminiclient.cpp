#include "geminiclient.h"

#include "../core/database.h"

#include <QJsonDocument>
#include <QJsonParseError>
#include <QNetworkRequest>
#include <QUrl>
#include <QDebug>

const QString GeminiClient::API_URL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

GeminiClient::GeminiClient(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
}

void GeminiClient::setDbManager(DatabaseManager* dbManager)
{
    m_dbManager = dbManager;
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
        qDebug() << "API key is not configured.";
        qDebug() << "Set GEMINI_API_KEY or GOOGLE_API_KEY.";
        return;
    }

    QUrl url("https://generativelanguage.googleapis.com/v1beta/models?key=" + m_apiKey);
    QNetworkRequest request(url);

    QNetworkReply* reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "Failed to fetch models:" << reply->errorString();
            reply->deleteLater();
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) {
            qDebug() << "Invalid models response.";
            reply->deleteLater();
            return;
        }

        const QJsonArray models = doc.object().value("models").toArray();
        qDebug() << "Available Gemini models:";
        for (const QJsonValue& modelValue : models) {
            const QJsonObject model = modelValue.toObject();
            const QString name = model.value("name").toString();
            if (!name.contains("gemini")) {
                continue;
            }
            qDebug() << "-" << name;
        }

        reply->deleteLater();
    });
}

QJsonArray GeminiClient::buildToolsPayload() const
{
    QJsonArray declarations;

    {
        QJsonObject tool;
        tool["name"] = "search_books";
        tool["description"] = "Find books by title, author text, or keywords from the store database.";

        QJsonObject properties;
        properties["query"] = QJsonObject{{"type", "STRING"}, {"description", "Search text"}};
        properties["limit"] = QJsonObject{{"type", "INTEGER"}, {"description", "Max results (1..20)"}};

        QJsonObject parameters;
        parameters["type"] = "OBJECT";
        parameters["properties"] = properties;
        QJsonArray required;
        required.append("query");
        parameters["required"] = required;
        tool["parameters"] = parameters;

        declarations.append(tool);
    }

    {
        QJsonObject tool;
        tool["name"] = "get_book_details";
        tool["description"] = "Get full details and availability for a specific book id.";

        QJsonObject properties;
        properties["book_id"] = QJsonObject{{"type", "INTEGER"}, {"description", "Book id"}};

        QJsonObject parameters;
        parameters["type"] = "OBJECT";
        parameters["properties"] = properties;
        QJsonArray required;
        required.append("book_id");
        parameters["required"] = required;
        tool["parameters"] = parameters;

        declarations.append(tool);
    }

    {
        QJsonObject tool;
        tool["name"] = "search_authors";
        tool["description"] = "Find authors by name and return ids for further lookups.";

        QJsonObject properties;
        properties["query"] = QJsonObject{{"type", "STRING"}, {"description", "Author name fragment"}};
        properties["limit"] = QJsonObject{{"type", "INTEGER"}, {"description", "Max results (1..20)"}};

        QJsonObject parameters;
        parameters["type"] = "OBJECT";
        parameters["properties"] = properties;
        QJsonArray required;
        required.append("query");
        parameters["required"] = required;
        tool["parameters"] = parameters;

        declarations.append(tool);
    }

    {
        QJsonObject tool;
        tool["name"] = "get_author_books";
        tool["description"] = "Return books written by a specific author id.";

        QJsonObject properties;
        properties["author_id"] = QJsonObject{{"type", "INTEGER"}, {"description", "Author id"}};

        QJsonObject parameters;
        parameters["type"] = "OBJECT";
        parameters["properties"] = properties;
        QJsonArray required;
        required.append("author_id");
        parameters["required"] = required;
        tool["parameters"] = parameters;

        declarations.append(tool);
    }

    QJsonObject toolSet;
    toolSet["functionDeclarations"] = declarations;

    QJsonArray tools;
    tools.append(toolSet);
    return tools;
}

QJsonObject GeminiClient::buildRequestBody(const QJsonArray& conversation, bool allowToolCalls) const
{
    QJsonObject requestBody;

    if (!m_systemPrompt.isEmpty()) {
        QJsonObject systemInstruction;
        systemInstruction["parts"] = QJsonArray{ QJsonObject{{"text", m_systemPrompt}} };
        requestBody["systemInstruction"] = systemInstruction;
    }

    requestBody["contents"] = conversation;
    requestBody["tools"] = buildToolsPayload();

    QJsonObject functionCallingConfig;
    functionCallingConfig["mode"] = allowToolCalls ? "AUTO" : "NONE";
    QJsonObject toolConfig;
    toolConfig["functionCallingConfig"] = functionCallingConfig;
    requestBody["toolConfig"] = toolConfig;

    QJsonObject generationConfig;
    generationConfig["temperature"] = 0.1;
    generationConfig["maxOutputTokens"] = 2048;
    generationConfig["topP"] = 0.9;
    generationConfig["topK"] = 20;
    requestBody["generationConfig"] = generationConfig;

    return requestBody;
}

QJsonObject GeminiClient::executeToolCall(const QString& functionName, const QJsonObject& args) const
{
    QJsonObject result;

    if (!m_dbManager) {
        result["ok"] = false;
        result["error"] = "Database is not available";
        return result;
    }

    auto clampLimit = [](int value, int fallback) {
        int v = value > 0 ? value : fallback;
        if (v < 1) {
            v = 1;
        }
        if (v > 20) {
            v = 20;
        }
        return v;
    };

    if (functionName == "search_books") {
        const QString query = args.value("query").toString().trimmed();
        const int limit = clampLimit(args.value("limit").toInt(8), 8);

        const QList<BookDisplayInfo> books = query.isEmpty()
            ? m_dbManager->getAllBooksForDisplay(limit, 0)
            : m_dbManager->searchBooksForDisplay(query, limit, 0);

        QJsonArray items;
        for (int i = 0; i < books.size() && i < limit; ++i) {
            const BookDisplayInfo& b = books.at(i);
            QJsonObject item;
            item["book_id"] = b.bookId;
            item["title"] = b.title;
            item["authors"] = b.authors;
            item["genre"] = b.genre;
            item["price"] = b.price;
            item["stock_quantity"] = b.stockQuantity;
            item["in_stock"] = b.stockQuantity > 0;
            item["cover_image_path"] = b.coverImagePath;
            items.append(item);
        }

        result["ok"] = true;
        result["query"] = query;
        result["count"] = items.size();
        result["books"] = items;
        return result;
    }

    if (functionName == "get_book_details") {
        int bookId = args.value("book_id").toInt();
        if (bookId <= 0) {
            bookId = args.value("bookId").toInt();
        }

        if (bookId <= 0) {
            result["ok"] = false;
            result["error"] = "book_id is required";
            return result;
        }

        const BookDetailsInfo details = m_dbManager->getBookDetails(bookId);
        if (!details.found) {
            result["ok"] = false;
            result["error"] = "Book not found";
            result["book_id"] = bookId;
            return result;
        }

        result["ok"] = true;
        result["book_id"] = details.bookId;
        result["title"] = details.title;
        result["authors"] = details.authors;
        result["genre"] = details.genre;
        result["description"] = details.description;
        result["language"] = details.language;
        result["publisher"] = details.publisherName;
        result["price"] = details.price;
        result["stock_quantity"] = details.stockQuantity;
        result["in_stock"] = details.stockQuantity > 0;
        result["cover_image_path"] = details.coverImagePath;
        return result;
    }

    if (functionName == "search_authors") {
        const QString query = args.value("query").toString().trimmed().toLower();
        const int limit = clampLimit(args.value("limit").toInt(8), 8);

        const QList<AuthorDisplayInfo> authors = m_dbManager->getAllAuthorsForDisplay();
        QJsonArray items;

        for (const AuthorDisplayInfo& a : authors) {
            const QString fullName = QString("%1 %2").arg(a.firstName, a.lastName).trimmed();
            if (!query.isEmpty() && !fullName.toLower().contains(query)) {
                continue;
            }

            QJsonObject item;
            item["author_id"] = a.authorId;
            item["full_name"] = fullName;
            item["nationality"] = a.nationality;
            item["image_path"] = a.imagePath;
            items.append(item);

            if (items.size() >= limit) {
                break;
            }
        }

        result["ok"] = true;
        result["query"] = query;
        result["count"] = items.size();
        result["authors"] = items;
        return result;
    }

    if (functionName == "get_author_books") {
        int authorId = args.value("author_id").toInt();
        if (authorId <= 0) {
            authorId = args.value("authorId").toInt();
        }

        if (authorId <= 0) {
            result["ok"] = false;
            result["error"] = "author_id is required";
            return result;
        }

        const AuthorDetailsInfo details = m_dbManager->getAuthorDetails(authorId);
        if (!details.found) {
            result["ok"] = false;
            result["error"] = "Author not found";
            result["author_id"] = authorId;
            return result;
        }

        QJsonArray books;
        for (const BookDisplayInfo& b : details.books) {
            QJsonObject item;
            item["book_id"] = b.bookId;
            item["title"] = b.title;
            item["authors"] = b.authors;
            item["genre"] = b.genre;
            item["price"] = b.price;
            item["stock_quantity"] = b.stockQuantity;
            item["in_stock"] = b.stockQuantity > 0;
            books.append(item);
        }

        result["ok"] = true;
        result["author_id"] = details.authorId;
        result["author_name"] = QString("%1 %2").arg(details.firstName, details.lastName).trimmed();
        result["books_count"] = books.size();
        result["books"] = books;
        return result;
    }

    result["ok"] = false;
    result["error"] = "Unknown function: " + functionName;
    return result;
}

void GeminiClient::sendMessage(const QString& message, const QString& context)
{
    if (m_apiKey.isEmpty()) {
        emit errorOccurred("API key is not configured. Set GEMINI_API_KEY.");
        return;
    }

    m_isLoading = true;
    emit isLoadingChanged();

    QString fullMessage = message;
    if (!context.trimmed().isEmpty()) {
        fullMessage = "Context:\n" + context + "\n\nUser request:\n" + message;
    }

    QJsonObject userContent;
    userContent["role"] = "user";
    userContent["parts"] = QJsonArray{ QJsonObject{{"text", fullMessage}} };

    QJsonArray conversation;
    conversation.append(userContent);

    const QJsonObject requestBody = buildRequestBody(conversation, true);
    const QByteArray payload = QJsonDocument(requestBody).toJson(QJsonDocument::Compact);

    QNetworkRequest request(QUrl(API_URL + "?key=" + m_apiKey));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply* reply = m_networkManager->post(request, payload);
    reply->setProperty("conversationJson", QString::fromUtf8(QJsonDocument(conversation).toJson(QJsonDocument::Compact)));
    reply->setProperty("toolDepth", 0);

    connect(reply, &QNetworkReply::finished, this, &GeminiClient::onReplyFinished);
}

void GeminiClient::onReplyFinished()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        return;
    }

    const auto finishWithError = [this, reply](const QString& message) {
        m_isLoading = false;
        emit isLoadingChanged();
        emit errorOccurred(message);
        reply->deleteLater();
    };

    if (reply->error() != QNetworkReply::NoError) {
        const QByteArray errorData = reply->readAll();
        QString errorMsg = "Network error: " + reply->errorString();

        const QJsonDocument errorDoc = QJsonDocument::fromJson(errorData);
        if (errorDoc.isObject()) {
            const QString apiError = errorDoc.object().value("error").toObject().value("message").toString();
            if (!apiError.isEmpty()) {
                errorMsg = "API error: " + apiError;
            }
        }

        finishWithError(errorMsg);
        return;
    }

    const QByteArray responseData = reply->readAll();
    const QJsonDocument responseDoc = QJsonDocument::fromJson(responseData);
    if (!responseDoc.isObject()) {
        finishWithError("Invalid response from Gemini.");
        return;
    }

    const QJsonObject rootObj = responseDoc.object();
    if (rootObj.contains("error")) {
        const QString apiError = rootObj.value("error").toObject().value("message").toString();
        finishWithError("API error: " + (apiError.isEmpty() ? QString("Unknown error") : apiError));
        return;
    }

    const QJsonArray candidates = rootObj.value("candidates").toArray();
    if (candidates.isEmpty()) {
        finishWithError("Empty response from Gemini.");
        return;
    }

    const QJsonObject candidate = candidates.first().toObject();
    QJsonObject candidateContent = candidate.value("content").toObject();
    if (candidateContent.isEmpty()) {
        finishWithError("Gemini returned no content.");
        return;
    }
    if (!candidateContent.contains("role")) {
        candidateContent["role"] = "model";
    }

    QString conversationJson = reply->property("conversationJson").toString();
    int toolDepth = reply->property("toolDepth").toInt();
    reply->deleteLater();

    QJsonParseError parseError;
    QJsonDocument conversationDoc = QJsonDocument::fromJson(conversationJson.toUtf8(), &parseError);
    QJsonArray conversation;
    if (parseError.error == QJsonParseError::NoError && conversationDoc.isArray()) {
        conversation = conversationDoc.array();
    }

    const QJsonArray parts = candidateContent.value("parts").toArray();
    QJsonObject functionCall;
    QString responseText;

    for (const QJsonValue& partValue : parts) {
        const QJsonObject partObj = partValue.toObject();
        if (partObj.contains("functionCall")) {
            functionCall = partObj.value("functionCall").toObject();
            break;
        }

        const QString text = partObj.value("text").toString();
        if (!text.isEmpty()) {
            if (!responseText.isEmpty()) {
                responseText += "\n";
            }
            responseText += text;
        }
    }

    if (!functionCall.isEmpty()) {
        if (toolDepth >= 8) {
            m_isLoading = false;
            emit isLoadingChanged();
            emit errorOccurred("Too many tool-calling steps. Please try a simpler request.");
            return;
        }

        const QString functionName = functionCall.value("name").toString();
        QJsonObject args = functionCall.value("args").toObject();
        if (args.isEmpty() && functionCall.value("args").isString()) {
            const QJsonDocument argsDoc = QJsonDocument::fromJson(functionCall.value("args").toString().toUtf8());
            if (argsDoc.isObject()) {
                args = argsDoc.object();
            }
        }

        qDebug() << "[AI TOOL] depth=" << toolDepth
                << "function=" << functionName
                << "args=" << QJsonDocument(args).toJson(QJsonDocument::Compact);

        const QJsonObject toolResult = executeToolCall(functionName, args);

        qDebug() << "[AI TOOL RESULT] function=" << functionName
                << "payload=" << QJsonDocument(toolResult).toJson(QJsonDocument::Compact).left(600);

        conversation.append(candidateContent);

        QJsonObject functionResponse;
        functionResponse["name"] = functionName;
        functionResponse["response"] = toolResult;

        QJsonObject functionResponsePart;
        functionResponsePart["functionResponse"] = functionResponse;

        QJsonObject toolReplyTurn;
        toolReplyTurn["role"] = "user";
        toolReplyTurn["parts"] = QJsonArray{ functionResponsePart };
        conversation.append(toolReplyTurn);

        const QJsonObject requestBody = buildRequestBody(conversation, false);
        const QByteArray payload = QJsonDocument(requestBody).toJson(QJsonDocument::Compact);

        QNetworkRequest request(QUrl(API_URL + "?key=" + m_apiKey));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

        QNetworkReply* nextReply = m_networkManager->post(request, payload);
        nextReply->setProperty("conversationJson", QString::fromUtf8(QJsonDocument(conversation).toJson(QJsonDocument::Compact)));
        nextReply->setProperty("toolDepth", toolDepth + 1);
        connect(nextReply, &QNetworkReply::finished, this, &GeminiClient::onReplyFinished);
        return;
    }

    m_isLoading = false;
    emit isLoadingChanged();

    if (responseText.trimmed().isEmpty()) {
        emit errorOccurred("Gemini returned an empty answer.");
        return;
    }

    qDebug() << "[AI FINAL]" << responseText.left(250);

    emit responseReceived(responseText.trimmed());
}
