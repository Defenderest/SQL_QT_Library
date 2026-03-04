import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Item {
    id: root

    property bool isChatOpen: false
    property bool isTyping: false
    property string currentContext: ""
    property bool dataLoaded: false
    property var chatHistory: []
    
    readonly property color bgBody: Theme.bgBody
    readonly property color bgElevated: Qt.rgba(1, 1, 1, 0.025)
    readonly property color borderLight: Theme.borderLight
    readonly property color borderHover: Theme.borderHover
    readonly property color borderStrong: Qt.rgba(1, 1, 1, 0.16)
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textSecondary: Theme.textSecondary
    readonly property color textMuted: Theme.textMuted
    readonly property color userBubble: Theme.accentWhite
    readonly property color aiBubble: Qt.rgba(1, 1, 1, 0.055)
    
    readonly property int spacingS: Theme.spacingS
    readonly property int spacingM: Theme.spacingM
    readonly property int spacingL: Theme.spacingL
    
    readonly property int radiusSoft: Theme.radiusSoft
    readonly property int radiusRound: Theme.radiusRound
    readonly property int radiusPill: Theme.radiusPill
    
    readonly property int animationFast: Theme.animationFast
    readonly property int animationSmooth: Theme.animationSmooth
    
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
        if (!geminiClient) {
            retryLoadData()
            return
        }

        root.currentContext = ""
        root.dataLoaded = true
        retryCount = 0
        setupSystemPrompt()
    }
    
    property int retryCount: 0
    property int maxRetries: 5
    
    function retryLoadData() {
        if (retryCount < maxRetries && !dataLoaded) {
            retryCount++
            Qt.callLater(function() {
                loadStoreData()
            })
        } else if (retryCount >= maxRetries) {
            root.currentContext = ""
            root.dataLoaded = true
            setupSystemPrompt()
        }
    }

    function setupSystemPrompt() {
        var prompt = "Ти — AI-консультант книжного магазину Library.\n\n" +
                     "ТВОЯ ГОЛОВНА ЗАДАЧА: допомагати клієнтам знаходити книги з НАШОГО каталогу.\n\n" +
                     "Ти маєш доступ до інструментів БД. Для питань про книги, авторів, ціну або наявність ОБОВ'ЯЗКОВО викликай tool-функції, а не вигадуй дані.\n\n" +
                     "ЖОРСТКІ ПРАВИЛА (порушення критичне):\n" +
                     "1. НЕ вигадуй книг, цін, залишків, авторів\n" +
                     "2. Для фактів використовуй лише результат tool-викликів\n" +
                     "3. Якщо tool-пошук не знаходить книгу — скажи: \"На жаль, цієї книги немає в наявності\"\n" +
                     "4. Не придумуй авторів, жанри, описи\n" +
                     "5. Пам'ятай історію розмови\n\n" +
                     "ЯК ВІДПОВІДАТИ:\n" +
                     "- Коротко, по суті\n" +
                     "- Одразу називай ціну та наявність\n" +
                     "- Пропонуй альтернативи з наявних книг\n" +
                     "- Якщо клієнт питає про книгу — виклич tool і дай точні дані\n\n"
        
        if (geminiClient) {
            geminiClient.setSystemPrompt(prompt)
        }
    }

    Rectangle {
        id: chatWindow
        width: 430
        height: 620
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: spacingL
        anchors.bottomMargin: spacingL
        radius: radiusSoft
        color: bgBody
        border.width: 1
        border.color: borderStrong
        clip: true
        visible: opacity > 0
        opacity: root.isChatOpen ? 1.0 : 0.0
        scale: root.isChatOpen ? 1.0 : 0.95

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, radiusSoft - 1)
            color: "transparent"
            border.width: 1
            border.color: borderLight
        }

        Behavior on opacity {
            NumberAnimation { duration: animationSmooth }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                color: bgElevated
                border.width: 1
                border.color: borderLight
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: spacingM

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 19
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: borderStrong
                        
                        Label {
                            anchors.centerIn: parent
                            text: "AI"
                            color: textPrimary
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 11
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: "AI Консультант"
                            color: textPrimary
                            font.family: Theme.fontBody.family
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        
                        RowLayout {
                            spacing: spacingS
                            
                            Rectangle {
                                Layout.preferredWidth: 7
                                Layout.preferredHeight: 7
                                radius: 3.5
                                color: {
                                    if (!geminiClient || geminiClient.apiKey.length === 0) 
                                        return Theme.error
                                    if (!dataLoaded) 
                                        return Theme.warning
                                    return Theme.success
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
                                font.family: Theme.fontCaption.family
                                font.pixelSize: 10
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.8
                            }
                        }
                    }

                    // Кнопка закриття
                    MouseArea {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 17
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            border.width: 1
                            border.color: borderLight
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "✕"
                            color: parent.containsMouse ? textPrimary : textSecondary
                            font.pixelSize: 13
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
                Layout.margins: 14
                clip: true
                spacing: 10
                model: ListModel {
                    ListElement { isUser: false; message: "Привіт! Я AI-консультант Library. Допоможу підібрати книгу з нашого каталогу. Пишіть назву книги або автора." }
                }
                
                // Typing indicator
                Rectangle {
                    visible: root.isTyping || (geminiClient && geminiClient.isLoading)
                    width: 64
                    height: 32
                    radius: 16
                    color: aiBubble
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: spacingS
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
                    height: bubble.height + 8
                    
                    Rectangle {
                        id: bubble
                        width: Math.min(chatWindow.width - 96, parent.width * 0.78)
                        height: msgText.paintedHeight + 24
                        anchors.right: isUser ? parent.right : undefined
                        anchors.left: isUser ? undefined : parent.left
                        radius: 18
                        color: isUser ? userBubble : aiBubble
                        border.width: 1
                        border.color: isUser ? Qt.rgba(1, 1, 1, 0.2) : borderLight
                        
                        Text {
                            id: msgText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            width: parent.width - 24
                            text: message
                            color: isUser ? bgBody : textPrimary
                            font.family: Theme.fontBody.family
                            font.pixelSize: 14
                            wrapMode: Text.Wrap
                            lineHeight: 1.3
                            lineHeightMode: Text.ProportionalHeight
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
                Layout.preferredHeight: 84
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
                        radius: 22
                        color: Qt.rgba(1, 1, 1, 0.015)
                        border.width: 1
                        border.color: inputField.activeFocus ? borderHover : borderLight

                        Behavior on border.color {
                            ColorAnimation { duration: animationFast }
                        }
                        
                        TextInput {
                            id: inputField
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            color: textPrimary
                            font.family: Theme.fontBody.family
                            font.pixelSize: 14
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
                                font.family: Theme.fontBody.family
                                font.pixelSize: 13
                                visible: inputField.text.length === 0 && !inputField.activeFocus
                            }
                            
                            onAccepted: sendMessage()
                        }
                    }

                    MouseArea {
                        id: sendArea
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        cursorShape: inputField.text.trim().length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: inputField.text.trim().length > 0 && geminiClient && geminiClient.apiKey.length > 0 && dataLoaded
                        hoverEnabled: true
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 22
                            color: sendArea.enabled
                                   ? (sendArea.containsMouse ? Theme.accentWhite : "transparent")
                                   : Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1
                            border.color: sendArea.enabled ? Theme.accentWhite : borderLight

                            Behavior on color {
                                ColorAnimation { duration: animationFast }
                            }
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: "→"
                            color: sendArea.enabled
                                   ? (sendArea.containsMouse ? bgBody : textPrimary)
                                   : textMuted
                            font.pixelSize: 18
                            font.family: Theme.fontBody.family
                        }
                        
                        onClicked: sendMessage()
                    }
                }
            }
        }
    }
    
    MouseArea {
        id: floatingButton
        width: 58
        height: 58
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: spacingL
        anchors.bottomMargin: spacingL
        visible: opacity > 0
        opacity: root.isChatOpen ? 0.0 : 1.0
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        
        Behavior on opacity {
            NumberAnimation { duration: animationSmooth }
        }

        Rectangle {
            anchors.fill: parent
            radius: 29
            color: floatingButton.containsMouse ? Theme.accentWhite : Qt.rgba(1, 1, 1, 0.07)
            border.width: 1
            border.color: Theme.accentWhite

            Behavior on color {
                ColorAnimation { duration: animationFast }
            }
            
            Label {
                anchors.centerIn: parent
                text: "AI"
                color: floatingButton.containsMouse ? bgBody : textPrimary
                font.family: Theme.fontCaption.family
                font.pixelSize: 12
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
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
            var fullContext = "ІСТОРІЯ РОЗМОВИ:\n"
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
