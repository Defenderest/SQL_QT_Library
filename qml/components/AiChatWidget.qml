import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property bool isChatOpen: false
    property bool isTyping: false
    property string currentContext: ""
    property bool dataLoaded: false
    property var chatHistory: []
    
    // Monochrome Obsidian theme
    readonly property color bgBody: "#030303"
    readonly property color bgElevated: "#141414"
    readonly property color borderLight: Qt.rgba(1, 1, 1, 0.08)
    readonly property color borderHover: Qt.rgba(1, 1, 1, 0.25)
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#888888"
    readonly property color textMuted: "#555555"
    readonly property color userBubble: "#ffffff"
    readonly property color aiBubble: Qt.rgba(1, 1, 1, 0.06)
    
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 20
    
    readonly property int radiusRound: 16
    readonly property int radiusPill: 30
    
    readonly property int animationFast: 150
    readonly property int animationSmooth: 400
    
    width: parent.width
    height: parent.height
    z: 1000

    // Завантажуємо дані при створенні компонента
    Component.onCompleted: {
        console.log("🤖 AI Chat Widget створено")
        loadStoreData()
    }
    
    // Load data when chat opens (якщо ще не завантажено)
    onIsChatOpenChanged: {
        if (isChatOpen && !dataLoaded) {
            loadStoreData()
        }
    }
    
    function loadStoreData() {
        console.log("📚 Завантаження даних магазину для AI...")
        
        if (!appContext) {
            console.log("⚠️ appContext не доступний")
            retryLoadData()
            return
        }
        
        // Отримуємо дані напряму з БД через appContext
        var catalog = appContext.getBooksCatalogForAI()
        
        if (catalog && catalog.length > 0) {
            root.currentContext = catalog
            root.dataLoaded = true
            retryCount = 0
            console.log("✅ Дані отримано! Довжина:", catalog.length)
            setupSystemPrompt()
        } else {
            console.log("⚠️ Каталог порожній, пробуємо ще раз...")
            retryLoadData()
        }
    }
    
    property int retryCount: 0
    property int maxRetries: 5
    
    function retryLoadData() {
        if (retryCount < maxRetries && !dataLoaded) {
            retryCount++
            console.log("🔄 Повторна спроба завантаження даних (" + retryCount + "/" + maxRetries + ")...")
            Qt.callLater(function() {
                loadStoreData()
            }, 1500)
        } else if (retryCount >= maxRetries) {
            console.log("❌ Досягнуто максимальну кількість спроб")
            root.currentContext = "Дані тимчасово недоступні. AI працює в обмеженому режимі."
            root.dataLoaded = true
            setupSystemPrompt()
        }
    }

    function setupSystemPrompt() {
        var prompt = "Ти — AI-консультант книжного магазину OBSIDIAN.LUXE.\n\n" +
                     "ТВОЯ ГОЛОВНА ЗАДАЧА: Допомагати клієнтам знаходити книги з НАШОГО каталогу.\n\n" +
                     "ЖОРСТКІ ПРАВИЛА (порушення критичне):\n" +
                     "1. Використовуй ТІЛЬКИ книги з списку нижче. НЕ ВИГАДУЙ книг!\n" +
                     "2. Ціни та наявність брати тільки з наведених даних\n" +
                     "3. Якщо книги немає в списку — скажи: \"На жаль, цієї книги немає в наявності\"\n" +
                     "4. Не придумуй авторів, жанри, описи\n" +
                     "5. Пам'ятай історію розмови\n\n" +
                     "ЯК ВІДПОВІДАТИ:\n" +
                     "- Коротко, по суті\n" +
                     "- Одразу називай ціну та наявність\n" +
                     "- Пропонуй альтернативи з наявних книг\n" +
                     "- Якщо клієнт питає про книгу — знайди її в списку та дай точні дані\n\n"
        
        if (root.currentContext.length > 0) {
            prompt += "\n=== НАШІ КНИГИ (використовуй тільки ці дані) ===\n" + 
                     root.currentContext + 
                     "\n===========================================\n"
        }
        
        if (geminiClient) {
            geminiClient.setSystemPrompt(prompt)
            console.log("✅ Системний промпт встановлено")
        }
    }

    Rectangle {
        id: chatWindow
        width: 400
        height: 560
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: spacingL
        anchors.bottomMargin: spacingL
        radius: 8
        color: bgBody
        border.width: 1
        border.color: borderLight
        visible: opacity > 0
        opacity: root.isChatOpen ? 1.0 : 0.0
        scale: root.isChatOpen ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: animationSmooth }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                color: bgElevated
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: spacingL
                    anchors.rightMargin: spacingL
                    spacing: spacingM

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        
                        Label {
                            anchors.centerIn: parent
                            text: "AI"
                            color: "#ffffff"
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: "AI Консультант"
                            color: textPrimary
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        
                        RowLayout {
                            spacing: spacingS
                            
                            Rectangle {
                                Layout.preferredWidth: 6
                                Layout.preferredHeight: 6
                                radius: 3
                                color: {
                                    if (!geminiClient || geminiClient.apiKey.length === 0) 
                                        return Qt.rgba(1, 0.5, 0.5, 0.8)
                                    if (!dataLoaded) 
                                        return Qt.rgba(1, 0.8, 0, 0.8)
                                    return Qt.rgba(0.2, 1, 0.2, 0.8)
                                }
                            }
                            
                            Label {
                                text: {
                                    if (!geminiClient || geminiClient.apiKey.length === 0) 
                                        return "API не налаштовано"
                                    if (!dataLoaded) 
                                        return "Завантаження..."
                                    return "Підключено"
                                }
                                color: textSecondary
                                font.family: "Inter"
                                font.pixelSize: 11
                            }
                        }
                    }

                    // Кнопка оновлення даних
                    MouseArea {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        visible: !dataLoaded
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "↻"
                            color: parent.containsMouse ? textPrimary : textSecondary
                            font.pixelSize: 16
                        }
                        
                        onClicked: {
                            console.log("🔄 Ручне оновлення даних...")
                            retryCount = 0
                            loadStoreData()
                        }
                    }

                    // Кнопка закриття
                    MouseArea {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "✕"
                            color: parent.containsMouse ? textPrimary : textSecondary
                            font.pixelSize: 14
                        }
                        
                        onClicked: root.isChatOpen = false
                    }
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: borderLight
                }
            }

            // Message Area
            ListView {
                id: messageList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: spacingL
                clip: true
                spacing: spacingM
                model: ListModel {
                    ListElement { isUser: false; message: "Привіт! Я AI-консультант OBSIDIAN.LUXE. Допоможу підібрати книгу з нашого каталогу. Пишіть назву книги або автора." }
                }
                
                // Typing indicator
                Rectangle {
                    visible: root.isTyping || (geminiClient && geminiClient.isLoading)
                    width: 70
                    height: 36
                    radius: radiusRound
                    color: aiBubble
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: spacingM
                    border.width: 1
                    border.color: borderLight
                    z: 100
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Repeater {
                            model: 3
                            Rectangle {
                                Layout.preferredWidth: 5
                                Layout.preferredHeight: 5
                                radius: 2.5
                                color: textSecondary
                                
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 600 }
                                    NumberAnimation { to: 1.0; duration: 600 }
                                }
                            }
                        }
                    }
                }
                
                delegate: Item {
                    width: messageList.width
                    height: bubble.height + spacingM
                    
                    Rectangle {
                        id: bubble
                        width: Math.min(320, parent.width * 0.75)
                        height: msgText.height + 20
                        anchors.right: isUser ? parent.right : undefined
                        anchors.left: isUser ? undefined : parent.left
                        radius: radiusRound
                        color: isUser ? userBubble : aiBubble
                        border.width: isUser ? 0 : 1
                        border.color: borderLight
                        
                        Text {
                            id: msgText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            width: parent.width - 20
                            text: message
                            color: isUser ? bgBody : textPrimary
                            font.family: "Inter"
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                            lineHeight: 1.25
                            lineHeightMode: Text.ProportionalHeight
                            maximumLineCount: 100
                            elide: Text.ElideNone
                        }
                    }
                }
                
                onCountChanged: {
                    Qt.callLater(function() {
                        positionViewAtEnd()
                    })
                }
            }

            // Input Area
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                color: bgElevated
                border.width: 1
                border.color: borderLight
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: spacingM
                    anchors.leftMargin: spacingL
                    anchors.rightMargin: spacingL
                    spacing: spacingM

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: radiusPill
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1
                        border.color: inputField.activeFocus ? borderHover : borderLight
                        
                        TextInput {
                            id: inputField
                            anchors.fill: parent
                            anchors.leftMargin: spacingL
                            anchors.rightMargin: spacingL
                            verticalAlignment: TextInput.AlignVCenter
                            color: textPrimary
                            font.family: "Inter"
                            font.pixelSize: 13
                            clip: true
                            selectByMouse: true
                            enabled: geminiClient && geminiClient.apiKey.length > 0 && dataLoaded
                            
                            Label {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (!geminiClient || geminiClient.apiKey.length === 0) 
                                        return "Налаштуйте GEMINI_API_KEY"
                                    if (!dataLoaded) 
                                        return "Завантаження каталогу..."
                                    return "Напишіть назву книги або автора..."
                                }
                                color: textMuted
                                font.family: "Inter"
                                font.pixelSize: 13
                                visible: inputField.text.length === 0 && !inputField.activeFocus
                            }
                            
                            onAccepted: sendMessage()
                        }
                    }

                    MouseArea {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        cursorShape: inputField.text.trim().length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: inputField.text.trim().length > 0 && geminiClient && geminiClient.apiKey.length > 0 && dataLoaded
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 22
                            color: inputField.text.trim().length > 0 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.05)
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "→"
                            color: inputField.text.trim().length > 0 ? bgBody : textMuted
                            font.pixelSize: 18
                            font.bold: true
                        }
                        
                        onClicked: sendMessage()
                    }
                }
            }
        }
    }
    
    MouseArea {
        id: floatingButton
        width: 56
        height: 56
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: spacingL
        anchors.bottomMargin: spacingL
        visible: opacity > 0
        opacity: root.isChatOpen ? 0.0 : 1.0
        cursorShape: Qt.PointingHandCursor
        
        Behavior on opacity {
            NumberAnimation { duration: animationSmooth }
        }

        Rectangle {
            anchors.fill: parent
            radius: 28
            color: "#ffffff"
            
            Label {
                anchors.centerIn: parent
                text: "AI"
                color: bgBody
                font.family: "Inter"
                font.pixelSize: 14
                font.bold: true
            }
        }

        onClicked: root.isChatOpen = true
    }
    
    // Gemini Client Connections
    Connections {
        target: geminiClient
        
        function onResponseReceived(response) {
            // Clean up markdown
            var cleanResponse = response
                .replace(/\*\*/g, "")
                .replace(/\*/g, "")
                .replace(/__/g, "")
                .replace(/_/g, "")
                .replace(/`{3}[\s\S]*?`{3}/g, "[код]")
                .replace(/`([^`]+)`/g, "$1")
                .replace(/#{1,6}\s/g, "")
            
            messageList.model.append({ 
                isUser: false, 
                message: cleanResponse 
            })
            
            // Додаємо до історії
            chatHistory.push({role: "model", text: cleanResponse})
        }
        
        function onErrorOccurred(error) {
            messageList.model.append({ 
                isUser: false, 
                message: "Помилка: " + error 
            })
        }
    }
    
    function sendMessage() {
        if (inputField.text.trim().length > 0 && geminiClient && geminiClient.apiKey.length > 0) {
            var message = inputField.text.trim()
            messageList.model.append({ isUser: true, message: message })
            inputField.text = ""
            
            // Додаємо до історії
            chatHistory.push({role: "user", text: message})
            
            // Формуємо контекст з історією
            var fullContext = currentContext + "\n\nІСТОРІЯ РОЗМОВИ:\n"
            for (var i = Math.max(0, chatHistory.length - 10); i < chatHistory.length; i++) {
                var entry = chatHistory[i]
                if (entry.role === "user") {
                    fullContext += "Клієнт: " + entry.text + "\n"
                } else {
                    fullContext += "Консультант: " + entry.text + "\n"
                }
            }
            
            // Send to Gemini
            geminiClient.sendMessage(message, fullContext)
        }
    }
}