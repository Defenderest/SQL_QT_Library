import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Item {
    id: root

    property int currentTab: 0
    property string toastMessage: ""
    property color toastColor: Theme.success
    property bool adminAllowed: appContext && appContext.isAdmin
    property bool compactLayout: width < 1220
    property int pagePadding: Math.max(20, Math.min(Theme.spacingXXL, Math.floor(Math.min(width, height) * 0.045)))

    property int booksCount: adminModel && adminModel.books ? adminModel.books.length : 0
    property int commentsCount: adminModel && adminModel.comments ? adminModel.comments.length : 0
    property int ordersCount: adminModel && adminModel.orders ? adminModel.orders.length : 0
    property int usersCount: adminModel && adminModel.users ? adminModel.users.length : 0

    readonly property var tabConfig: [
        { title: "Книги", subtitle: "Каталог і ціни" },
        { title: "Коментарі", subtitle: "Модерація" },
        { title: "Замовлення", subtitle: "Статуси" },
        { title: "Користувачі", subtitle: "Доступи" }
    ]

    function parseNumber(text, fallbackValue) {
        var value = Number(text)
        return isNaN(value) ? fallbackValue : value
    }

    function showToast(message, color) {
        toastMessage = message
        toastColor = color
        toastTimer.restart()
    }

    function loadDataIfAllowed() {
        if (root.adminAllowed && adminModel) {
            adminModel.loadAllData()
        }
    }

    Component.onCompleted: loadDataIfAllowed()

    Connections {
        target: appContext
        function onIsAdminChanged() { root.loadDataIfAllowed() }
    }

    Connections {
        target: adminModel
        function onErrorOccurred(message) { root.showToast(message, Theme.error) }
        function onInfoMessage(message) { root.showToast(message, Theme.success) }
    }

    Timer {
        id: toastTimer
        interval: 3200
        onTriggered: root.toastMessage = ""
    }

    component AdminField: TextField {
        color: Theme.textPrimary
        placeholderTextColor: Theme.textMuted
        font.family: Theme.fontBody.family
        font.pixelSize: 13
        selectedTextColor: Theme.bgBody
        selectionColor: Theme.accentWhite
        leftPadding: 12
        rightPadding: 12
        topPadding: 10
        bottomPadding: 10

        background: Rectangle {
            radius: Theme.radiusSoft
            color: Qt.rgba(1, 1, 1, 0.018)
            border.width: 1
            border.color: parent.activeFocus ? Theme.borderHover : Theme.borderLight

            Behavior on border.color {
                ColorAnimation { duration: Theme.animationFast }
            }
        }
    }

    component ActionButton: Rectangle {
        id: buttonRoot

        property string text: ""
        property color normalColor: "transparent"
        property color hoverColor: Qt.rgba(1, 1, 1, 0.08)
        property color borderColor: Theme.borderLight
        property color textColor: Theme.textPrimary
        property int buttonHeight: 36
        property int sidePadding: 16
        signal clicked()

        implicitWidth: Math.max(120, label.implicitWidth + sidePadding * 2)
        implicitHeight: buttonHeight
        radius: Theme.radiusPill
        border.width: 1
        border.color: buttonRoot.borderColor
        color: area.containsMouse ? hoverColor : normalColor

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }

        Label {
            id: label
            anchors.centerIn: parent
            text: buttonRoot.text
            color: buttonRoot.textColor
            font.family: Theme.fontCaption.family
            font.pixelSize: 11
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: buttonRoot.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pagePadding
        spacing: Theme.spacingM

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.adminAllowed
            color: Qt.rgba(1, 1, 1, 0.015)
            border.width: 1
            border.color: Theme.borderLight
            radius: Theme.radiusSoft

            Column {
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, 420)
                spacing: Theme.spacingM

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Доступ до адмін-панелі обмежено"
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 28
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Увійдіть під обліковим записом адміністратора, щоб керувати каталогом, замовленнями та ролями користувачів."
                    color: Theme.textSecondary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                }

                ActionButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "На головну"
                    normalColor: Theme.accentWhite
                    hoverColor: Qt.rgba(1, 1, 1, 0.82)
                    borderColor: Theme.accentWhite
                    textColor: Theme.bgBody
                    onClicked: appContext.navigateTo("home")
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.adminAllowed

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacingM

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 116
                    radius: Theme.radiusSoft
                    border.width: 1
                    border.color: Theme.borderLight
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.05) }
                        GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0.02) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.01) }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingL
                        spacing: Theme.spacingL

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: "Адмін-панель"
                                color: Theme.textPrimary
                                font.family: Theme.fontDisplay.family
                                font.pixelSize: 30
                            }

                            Label {
                                text: "Керуйте контентом, модерацією та ролями в одному робочому просторі."
                                color: Theme.textSecondary
                                font.family: Theme.fontBody.family
                                font.pixelSize: 13
                            }
                        }

                        RowLayout {
                            spacing: Theme.spacingS

                            Repeater {
                                model: [
                                    { label: "Книги", value: root.booksCount },
                                    { label: "Коментарі", value: root.commentsCount },
                                    { label: "Замовлення", value: root.ordersCount },
                                    { label: "Користувачі", value: root.usersCount }
                                ]

                                Rectangle {
                                    Layout.preferredWidth: root.compactLayout ? 72 : 96
                                    Layout.preferredHeight: 60
                                    radius: Theme.radiusSoft
                                    color: Qt.rgba(1, 1, 1, 0.035)
                                    border.width: 1
                                    border.color: Theme.borderLight

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2

                                        Label {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.value
                                            color: Theme.textPrimary
                                            font.family: Theme.fontDisplay.family
                                            font.pixelSize: 18
                                        }

                                        Label {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.label
                                            color: Theme.textMuted
                                            font.family: Theme.fontCaption.family
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }
                        }

                        ActionButton {
                            text: "Оновити"
                            normalColor: Theme.accentWhite
                            hoverColor: Qt.rgba(1, 1, 1, 0.84)
                            borderColor: Theme.accentWhite
                            textColor: Theme.bgBody
                            onClicked: root.loadDataIfAllowed()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 72
                    radius: Theme.radiusSoft
                    color: Qt.rgba(1, 1, 1, 0.018)
                    border.width: 1
                    border.color: Theme.borderLight

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Repeater {
                            model: root.tabConfig

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                radius: Theme.radiusRound
                                border.width: 1
                                border.color: root.currentTab === index ? Theme.accentWhite : Theme.borderLight
                                color: root.currentTab === index
                                       ? Theme.accentWhite
                                       : (tabArea.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 0

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.title
                                        color: root.currentTab === index ? Theme.bgBody : Theme.textPrimary
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 13
                                    }

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: !root.compactLayout
                                        text: modelData.subtitle
                                        color: root.currentTab === index ? Qt.rgba(3 / 255, 3 / 255, 3 / 255, 0.65) : Theme.textMuted
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 9
                                    }
                                }

                                MouseArea {
                                    id: tabArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentTab = index
                                }
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: {
                        if (root.currentTab === 0) return booksTab
                        if (root.currentTab === 1) return commentsTab
                        if (root.currentTab === 2) return ordersTab
                        return usersTab
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.pagePadding
        anchors.bottomMargin: root.pagePadding
        width: Math.min(parent.width * 0.42, toastLabel.implicitWidth + 36)
        height: toastLabel.implicitHeight + 20
        radius: Theme.radiusSoft
        color: root.toastColor
        opacity: root.toastMessage.length > 0 ? 1 : 0
        visible: opacity > 0
        z: 100

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationFast }
        }

        Label {
            id: toastLabel
            anchors.centerIn: parent
            width: parent.width - 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: root.toastMessage
            color: Theme.bgBody
            font.family: Theme.fontBody.family
            font.pixelSize: 12
        }
    }

    Component {
        id: booksTab

        ColumnLayout {
            spacing: Theme.spacingM

            Rectangle {
                Layout.fillWidth: true
                radius: Theme.radiusSoft
                color: Qt.rgba(1, 1, 1, 0.018)
                border.width: 1
                border.color: Theme.borderLight
                implicitHeight: addBookContent.implicitHeight + Theme.spacingL * 2

                ColumnLayout {
                    id: addBookContent
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: "Додати нову книгу"
                            color: Theme.textPrimary
                            font.family: Theme.fontDisplay.family
                            font.pixelSize: 21
                        }

                        Label {
                            text: "Швидке створення"
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1.1
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.width > 1460 ? 4 : (root.width > 1060 ? 3 : 2)
                        rowSpacing: Theme.spacingS
                        columnSpacing: Theme.spacingS

                        AdminField { id: addTitleField; placeholderText: "Назва"; Layout.fillWidth: true }
                        AdminField {
                            id: addPriceField
                            placeholderText: "Ціна"
                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                            Layout.fillWidth: true
                        }
                        AdminField {
                            id: addStockField
                            placeholderText: "Залишок"
                            validator: IntValidator { bottom: 0 }
                            Layout.fillWidth: true
                        }
                        AdminField { id: addGenreField; placeholderText: "Жанр"; Layout.fillWidth: true }
                        AdminField { id: addLanguageField; placeholderText: "Мова"; Layout.fillWidth: true }
                        AdminField { id: addCoverField; placeholderText: "Шлях до обкладинки"; Layout.fillWidth: true }
                        AdminField {
                            id: addDescriptionField
                            placeholderText: "Опис"
                            Layout.fillWidth: true
                            Layout.columnSpan: root.width > 1460 ? 2 : 1
                        }

                        ActionButton {
                            Layout.fillWidth: true
                            text: "Додати книгу"
                            normalColor: Theme.accentWhite
                            hoverColor: Qt.rgba(1, 1, 1, 0.84)
                            borderColor: Theme.accentWhite
                            textColor: Theme.bgBody
                            onClicked: {
                                var ok = adminModel.addBook(
                                    addTitleField.text,
                                    root.parseNumber(addPriceField.text, -1),
                                    root.parseNumber(addStockField.text, -1),
                                    addGenreField.text,
                                    addLanguageField.text,
                                    addDescriptionField.text,
                                    addCoverField.text
                                )
                                if (ok) {
                                    addTitleField.text = ""
                                    addPriceField.text = ""
                                    addStockField.text = ""
                                    addGenreField.text = ""
                                    addLanguageField.text = ""
                                    addDescriptionField.text = ""
                                    addCoverField.text = ""
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusSoft
                color: Qt.rgba(1, 1, 1, 0.012)
                border.width: 1
                border.color: Theme.borderLight

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: "Каталог книг"
                            color: Theme.textPrimary
                            font.family: Theme.fontDisplay.family
                            font.pixelSize: 20
                        }

                        Label {
                            text: root.booksCount + " позицій"
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.preferredWidth: 74
                            text: "ID"
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Книга"
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                        }

                        Label {
                            Layout.preferredWidth: 130
                            text: "Ціна"
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                        }

                        Label {
                            Layout.preferredWidth: root.compactLayout ? 208 : 268
                            text: "Дії"
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.borderLight
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: root.booksCount === 0
                        text: "Поки що немає книг для керування."
                        color: Theme.textSecondary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        Column {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: adminModel.books

                                Rectangle {
                                    width: parent.width
                                    height: 74
                                    radius: Theme.radiusSoft
                                    color: bookHover.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.015)
                                    border.width: 1
                                    border.color: Theme.borderLight

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animationFast }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        spacing: Theme.spacingS

                                        Label {
                                            Layout.preferredWidth: 74
                                            text: "#" + (modelData.bookId || "")
                                            color: Theme.textSecondary
                                            font.pixelSize: 13
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.title || ""
                                                color: Theme.textPrimary
                                                font.pixelSize: 14
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: (modelData.genre || "Без жанру") + " • " + (modelData.language || "-")
                                                color: Theme.textMuted
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        AdminField {
                                            id: priceField
                                            Layout.preferredWidth: 130
                                            text: modelData.price !== undefined ? Number(modelData.price).toFixed(2) : ""
                                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                                        }

                                        ActionButton {
                                            text: "Ціна"
                                            implicitWidth: 96
                                            onClicked: adminModel.updateBookPrice(modelData.bookId, root.parseNumber(priceField.text, -1))
                                        }

                                        ActionButton {
                                            text: "Видалити"
                                            implicitWidth: 108
                                            borderColor: Theme.error
                                            textColor: Theme.error
                                            hoverColor: Qt.rgba(244 / 255, 67 / 255, 54 / 255, 0.14)
                                            onClicked: adminModel.deleteBook(modelData.bookId)
                                        }
                                    }

                                    MouseArea {
                                        id: bookHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: commentsTab

        Rectangle {
            radius: Theme.radiusSoft
            color: Qt.rgba(1, 1, 1, 0.012)
            border.width: 1
            border.color: Theme.borderLight

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        Layout.fillWidth: true
                        text: "Модерація коментарів"
                        color: Theme.textPrimary
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 20
                    }

                    Label {
                        text: root.commentsCount + " записів"
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.borderLight
                }

                Label {
                    Layout.fillWidth: true
                    visible: root.commentsCount === 0
                    text: "Коментарів для модерації не знайдено."
                    color: Theme.textSecondary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Column {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: adminModel.comments

                            Rectangle {
                                width: parent.width
                                radius: Theme.radiusSoft
                                color: commentHover.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.015)
                                border.width: 1
                                border.color: Theme.borderLight
                                implicitHeight: commentCol.implicitHeight + 16

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }

                                ColumnLayout {
                                    id: commentCol
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    spacing: 5

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Label {
                                            Layout.fillWidth: true
                                            text: "#" + (modelData.commentId || "") + "  •  " + (modelData.bookTitle || "Книга")
                                            color: Theme.textPrimary
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 34
                                            Layout.preferredHeight: 24
                                            radius: 12
                                            color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.07)
                                            border.width: 1
                                            border.color: Theme.borderLight

                                            Label {
                                                anchors.centerIn: parent
                                                text: modelData.rating !== undefined ? modelData.rating : "-"
                                                color: Theme.textPrimary
                                                font.pixelSize: 11
                                            }
                                        }

                                        ActionButton {
                                            text: "Очистити"
                                            implicitWidth: 116
                                            buttonHeight: 30
                                            borderColor: Theme.error
                                            textColor: Theme.error
                                            hoverColor: Qt.rgba(244 / 255, 67 / 255, 54 / 255, 0.14)
                                            onClicked: adminModel.deleteComment(modelData.commentId)
                                        }
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: (modelData.authorName || "") + "  •  " + (modelData.commentDate || "")
                                        color: Theme.textMuted
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.commentText || ""
                                        color: Theme.textPrimary
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 13
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                MouseArea {
                                    id: commentHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: ordersTab

        ColumnLayout {
            spacing: Theme.spacingM

            Rectangle {
                Layout.fillWidth: true
                radius: Theme.radiusSoft
                color: Qt.rgba(1, 1, 1, 0.018)
                border.width: 1
                border.color: Theme.borderLight
                implicitHeight: orderFormContent.implicitHeight + Theme.spacingL * 2

                ColumnLayout {
                    id: orderFormContent
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Label {
                        text: "Додати статус замовлення"
                        color: Theme.textPrimary
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 21
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingS

                        AdminField {
                            id: orderIdField
                            Layout.preferredWidth: 150
                            placeholderText: "Order ID"
                            validator: IntValidator { bottom: 1 }
                        }

                        AdminField {
                            id: statusField
                            Layout.fillWidth: true
                            placeholderText: "Статус"
                        }

                        AdminField {
                            id: trackingField
                            Layout.preferredWidth: 220
                            placeholderText: "Tracking"
                        }

                        ActionButton {
                            text: "Додати"
                            normalColor: Theme.accentWhite
                            hoverColor: Qt.rgba(1, 1, 1, 0.84)
                            borderColor: Theme.accentWhite
                            textColor: Theme.bgBody
                            onClicked: {
                                var ok = adminModel.addOrderStatus(
                                    root.parseNumber(orderIdField.text, -1),
                                    statusField.text,
                                    trackingField.text
                                )
                                if (ok) {
                                    orderIdField.text = ""
                                    statusField.text = ""
                                    trackingField.text = ""
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusSoft
                color: Qt.rgba(1, 1, 1, 0.012)
                border.width: 1
                border.color: Theme.borderLight

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: "Замовлення"
                            color: Theme.textPrimary
                            font.family: Theme.fontDisplay.family
                            font.pixelSize: 20
                        }

                        Label {
                            text: root.ordersCount + " у списку"
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.borderLight
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: root.ordersCount === 0
                        text: "Немає замовлень для відображення."
                        color: Theme.textSecondary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        Column {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: adminModel.orders

                                Rectangle {
                                    width: parent.width
                                    radius: Theme.radiusSoft
                                    height: 82
                                    color: orderHover.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.015)
                                    border.width: 1
                                    border.color: Theme.borderLight

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animationFast }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingS
                                        spacing: Theme.spacingM

                                        Label {
                                            Layout.preferredWidth: 78
                                            text: "#" + (modelData.orderId || "")
                                            color: Theme.textPrimary
                                            font.pixelSize: 13
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.customerName || ""
                                                color: Theme.textPrimary
                                                font.pixelSize: 13
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.shippingAddress || ""
                                                color: Theme.textSecondary
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Label {
                                            Layout.preferredWidth: 130
                                            text: Number(modelData.totalAmount || 0).toFixed(2) + " UAH"
                                            color: Theme.textPrimary
                                            font.pixelSize: 13
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: root.compactLayout ? 148 : 190
                                            Layout.preferredHeight: 32
                                            radius: Theme.radiusPill
                                            color: Qt.rgba(33 / 255, 150 / 255, 243 / 255, 0.15)
                                            border.width: 1
                                            border.color: Qt.rgba(33 / 255, 150 / 255, 243 / 255, 0.45)

                                            Label {
                                                anchors.centerIn: parent
                                                width: parent.width - 18
                                                text: modelData.lastStatus || "-"
                                                color: Theme.info
                                                font.family: Theme.fontCaption.family
                                                font.pixelSize: 10
                                                font.capitalization: Font.AllUppercase
                                                elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: orderHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: usersTab

        Rectangle {
            radius: Theme.radiusSoft
            color: Qt.rgba(1, 1, 1, 0.012)
            border.width: 1
            border.color: Theme.borderLight

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        Layout.fillWidth: true
                        text: "Користувачі та ролі"
                        color: Theme.textPrimary
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 20
                    }

                    Label {
                        text: root.usersCount + " акаунтів"
                        visible: !root.compactLayout
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.borderLight
                }

                Label {
                    Layout.fillWidth: true
                    visible: root.usersCount === 0
                    text: "Список користувачів порожній."
                    color: Theme.textSecondary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Column {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: adminModel.users

                            Rectangle {
                                width: parent.width
                                radius: Theme.radiusSoft
                                height: root.compactLayout ? 82 : 74
                                color: userHover.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.015)
                                border.width: 1
                                border.color: Theme.borderLight

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingS
                                    spacing: root.compactLayout ? Theme.spacingS : Theme.spacingM

                                    Label {
                                        Layout.preferredWidth: root.compactLayout ? 56 : 72
                                        text: "#" + (modelData.customerId || "")
                                        color: Theme.textSecondary
                                        font.pixelSize: 13
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.fullName || ""
                                            color: Theme.textPrimary
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.email || ""
                                            color: Theme.textSecondary
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Label {
                                        visible: !root.compactLayout
                                        Layout.preferredWidth: 84
                                        text: (modelData.loyaltyPoints || 0) + " LP"
                                        color: Theme.textMuted
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: root.compactLayout ? 56 : 118
                                        Layout.preferredHeight: 34
                                        radius: 17
                                        color: Qt.rgba(1, 1, 1, 0.02)
                                        border.width: 1
                                        border.color: Theme.borderLight

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 6

                                            Label {
                                                visible: !root.compactLayout
                                                text: "Адмін"
                                                color: Theme.textSecondary
                                                font.pixelSize: 12
                                            }

                                            Switch {
                                                id: adminSwitch
                                                checked: modelData.isAdmin || false
                                                onToggled: adminModel.setUserAdminRole(modelData.customerId, checked)

                                                padding: 0
                                                implicitWidth: 44
                                                implicitHeight: 24
                                                Layout.alignment: Qt.AlignVCenter

                                                indicator: Rectangle {
                                                    implicitWidth: 44
                                                    implicitHeight: 24
                                                    radius: 12
                                                    color: adminSwitch.checked ? Qt.rgba(76 / 255, 175 / 255, 80 / 255, 0.35) : Qt.rgba(1, 1, 1, 0.1)
                                                    border.width: 1
                                                    border.color: adminSwitch.checked ? Theme.success : Theme.borderLight

                                                    Rectangle {
                                                        width: 18
                                                        height: 18
                                                        radius: 9
                                                        y: 3
                                                        x: adminSwitch.checked ? parent.width - width - 3 : 3
                                                        color: Theme.accentWhite

                                                        Behavior on x {
                                                            NumberAnimation { duration: Theme.animationFast }
                                                        }
                                                    }
                                                }

                                                contentItem: Item {}
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: userHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
