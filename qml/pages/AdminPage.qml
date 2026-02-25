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

    property string booksQuery: ""
    property string commentsQuery: ""
    property string ordersQuery: ""
    property string usersQuery: ""
    property bool lowStockOnly: false
    property bool usersAdminsOnly: false

    property int lowStockCount: {
        if (!adminModel || !adminModel.books) {
            return 0
        }
        var c = 0
        for (var i = 0; i < adminModel.books.length; ++i) {
            var b = adminModel.books[i]
            var stock = Number(b.stockQuantity || 0)
            if (!isNaN(stock) && stock > 0 && stock <= 5) {
                c++
            }
        }
        return c
    }

    property var filteredBooks: booksViewModel()
    property var filteredComments: commentsViewModel()
    property var filteredOrders: ordersViewModel()
    property var filteredUsers: usersViewModel()

    property int pendingOrdersCount: {
        if (!adminModel || !adminModel.orders) {
            return 0
        }
        var c = 0
        for (var i = 0; i < adminModel.orders.length; ++i) {
            var o = adminModel.orders[i]
            var s = String(o.lastStatus || "").toLowerCase()
            if (s.indexOf("new") !== -1 || s.indexOf("pending") !== -1 || s.indexOf("processing") !== -1 || s.indexOf("очіку") !== -1) {
                c++
            }
        }
        return c
    }

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

    function textValue(v) {
        return String(v === undefined || v === null ? "" : v).toLowerCase()
    }

    function booksViewModel() {
        var data = adminModel && adminModel.books ? adminModel.books : []
        var q = booksQuery.trim().toLowerCase()
        var filtered = []
        for (var i = 0; i < data.length; ++i) {
            var b = data[i]
            var stock = Number(b.stockQuantity || 0)
            if (lowStockOnly && (isNaN(stock) || stock <= 0 || stock > 5)) {
                continue
            }

            if (q.length === 0) {
                filtered.push(b)
                continue
            }

            var hay = textValue(b.title) + " " + textValue(b.genre) + " " + textValue(b.language) + " " + textValue(b.bookId)
            if (hay.indexOf(q) !== -1) {
                filtered.push(b)
            }
        }
        return filtered
    }

    function commentsViewModel() {
        var data = adminModel && adminModel.comments ? adminModel.comments : []
        var q = commentsQuery.trim().toLowerCase()
        if (q.length === 0) {
            return data
        }
        var filtered = []
        for (var i = 0; i < data.length; ++i) {
            var c = data[i]
            var hay = textValue(c.commentId) + " " + textValue(c.bookTitle) + " " + textValue(c.authorName) + " " + textValue(c.commentText)
            if (hay.indexOf(q) !== -1) {
                filtered.push(c)
            }
        }
        return filtered
    }

    function ordersViewModel() {
        var data = adminModel && adminModel.orders ? adminModel.orders : []
        var q = ordersQuery.trim().toLowerCase()
        if (q.length === 0) {
            return data
        }
        var filtered = []
        for (var i = 0; i < data.length; ++i) {
            var o = data[i]
            var hay = textValue(o.orderId) + " " + textValue(o.customerName) + " " + textValue(o.shippingAddress) + " " + textValue(o.lastStatus)
            if (hay.indexOf(q) !== -1) {
                filtered.push(o)
            }
        }
        return filtered
    }

    function usersViewModel() {
        var data = adminModel && adminModel.users ? adminModel.users : []
        var q = usersQuery.trim().toLowerCase()
        var filtered = []
        for (var i = 0; i < data.length; ++i) {
            var u = data[i]
            if (usersAdminsOnly && !u.isAdmin) {
                continue
            }

            if (q.length === 0) {
                filtered.push(u)
                continue
            }

            var hay = textValue(u.customerId) + " " + textValue(u.fullName) + " " + textValue(u.email)
            if (hay.indexOf(q) !== -1) {
                filtered.push(u)
            }
        }
        return filtered
    }

    function orderStatusTheme(statusText) {
        var status = textValue(statusText)
        if (status.indexOf("delivered") !== -1 || status.indexOf("вруч") !== -1 || status.indexOf("достав") !== -1) {
            return {
                bg: Qt.rgba(76 / 255, 175 / 255, 80 / 255, 0.16),
                border: Qt.rgba(76 / 255, 175 / 255, 80 / 255, 0.45),
                text: Theme.success
            }
        }
        if (status.indexOf("cancel") !== -1 || status.indexOf("скас") !== -1 || status.indexOf("reject") !== -1) {
            return {
                bg: Qt.rgba(244 / 255, 67 / 255, 54 / 255, 0.16),
                border: Qt.rgba(244 / 255, 67 / 255, 54 / 255, 0.45),
                text: Theme.error
            }
        }
        if (status.indexOf("pending") !== -1 || status.indexOf("new") !== -1 || status.indexOf("очіку") !== -1 || status.indexOf("processing") !== -1) {
            return {
                bg: Qt.rgba(255 / 255, 152 / 255, 0 / 255, 0.16),
                border: Qt.rgba(255 / 255, 152 / 255, 0 / 255, 0.45),
                text: Theme.warning
            }
        }

        return {
            bg: Qt.rgba(33 / 255, 150 / 255, 243 / 255, 0.15),
            border: Qt.rgba(33 / 255, 150 / 255, 243 / 255, 0.45),
            text: Theme.info
        }
    }

    function currentTabHint() {
        if (currentTab === 0) {
            return "Оновлюйте ціни та залишки, щоб каталог завжди був актуальний."
        }
        if (currentTab === 1) {
            return "Переглядайте нові відгуки та видаляйте некоректні коментарі."
        }
        if (currentTab === 2) {
            return "Додавайте статуси, щоб клієнт бачив прогрес свого замовлення."
        }
        return "Керуйте ролями адміністраторів та контролюйте доступ до панелі."
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

    component AdminSearchField: TextField {
        color: Theme.textPrimary
        placeholderTextColor: Theme.textMuted
        font.family: Theme.fontBody.family
        font.pixelSize: 13
        leftPadding: 38
        rightPadding: 12
        topPadding: 10
        bottomPadding: 10

        background: Rectangle {
            radius: Theme.radiusRound
            color: Qt.rgba(1, 1, 1, 0.018)
            border.width: 1
            border.color: parent.activeFocus ? Theme.borderHover : Theme.borderLight

            Behavior on border.color {
                ColorAnimation { duration: Theme.animationFast }
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "⌕"
                color: Theme.textMuted
                font.family: Theme.fontBody.family
                font.pixelSize: 14
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
        property int buttonHeight: 34
        property int sidePadding: 14
        property int cornerRadius: Theme.radiusRound
        signal clicked()

        implicitWidth: Math.max(120, label.implicitWidth + sidePadding * 2)
        implicitHeight: buttonHeight
        radius: buttonRoot.cornerRadius
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
                                    { label: "Книги", value: root.booksCount, tab: 0, hint: root.lowStockCount > 0 ? ("Мало залишку: " + root.lowStockCount) : "" },
                                    { label: "Коментарі", value: root.commentsCount, tab: 1, hint: "" },
                                    { label: "Замовлення", value: root.ordersCount, tab: 2, hint: root.pendingOrdersCount > 0 ? ("Очікують: " + root.pendingOrdersCount) : "" },
                                    { label: "Користувачі", value: root.usersCount, tab: 3, hint: "" }
                                ]

                                Rectangle {
                                    Layout.preferredWidth: root.compactLayout ? 72 : 96
                                    Layout.preferredHeight: 60
                                    radius: Theme.radiusSoft
                                    color: root.currentTab === modelData.tab
                                           ? Qt.rgba(1, 1, 1, 0.11)
                                           : (metricHover.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.035))
                                    border.width: 1
                                    border.color: root.currentTab === modelData.tab ? Theme.borderHover : Theme.borderLight

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animationFast }
                                    }

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

                                    Rectangle {
                                        visible: modelData.hint.length > 0
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.topMargin: -6
                                        anchors.rightMargin: -6
                                        radius: 7
                                        color: Theme.warning
                                        width: 14
                                        height: 14
                                    }

                                    MouseArea {
                                        id: metricHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.currentTab = modelData.tab
                                    }

                                    ToolTip.visible: metricHover.containsMouse && modelData.hint.length > 0
                                    ToolTip.text: modelData.hint
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

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Theme.radiusSoft
                    color: Qt.rgba(1, 1, 1, 0.012)
                    border.width: 1
                    border.color: Theme.borderLight

                    Label {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        verticalAlignment: Text.AlignVCenter
                        text: root.currentTabHint()
                        color: Theme.textSecondary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                        elide: Text.ElideRight
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
                            Layout.alignment: Qt.AlignLeft
                            Layout.preferredWidth: 186
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
                            text: root.filteredBooks.length + " із " + root.booksCount
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingS

                        AdminSearchField {
                            Layout.fillWidth: true
                            placeholderText: "Пошук за назвою, жанром або ID"
                            text: root.booksQuery
                            onTextChanged: root.booksQuery = text
                        }

                        ActionButton {
                            text: root.lowStockOnly ? "Усі залишки" : "Малий залишок"
                            implicitWidth: 146
                            borderColor: root.lowStockOnly ? Theme.warning : Theme.borderLight
                            textColor: root.lowStockOnly ? Theme.warning : Theme.textPrimary
                            hoverColor: root.lowStockOnly
                                       ? Qt.rgba(255 / 255, 152 / 255, 0 / 255, 0.16)
                                       : Qt.rgba(1, 1, 1, 0.08)
                            onClicked: root.lowStockOnly = !root.lowStockOnly
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
                        visible: root.filteredBooks.length === 0
                        text: root.booksCount === 0
                              ? "Поки що немає книг для керування."
                              : "Нічого не знайдено за поточним фільтром."
                        color: Theme.textSecondary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ScrollView {
                        id: booksScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        contentWidth: availableWidth

                        Column {
                            width: booksScroll.availableWidth
                            spacing: 8

                            Repeater {
                                model: root.filteredBooks.length

                                Rectangle {
                                    property var row: root.filteredBooks[index]
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
                                            text: "#" + (row.bookId || "")
                                            color: Theme.textSecondary
                                            font.pixelSize: 13
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Label {
                                                Layout.fillWidth: true
                                                text: row.title || ""
                                                color: Theme.textPrimary
                                                font.pixelSize: 14
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: (row.genre || "Без жанру")
                                                      + " • " + (row.language || "-")
                                                      + " • Залишок: " + (row.stockQuantity !== undefined ? row.stockQuantity : "-")
                                                color: Number(row.stockQuantity || 0) <= 5 ? Theme.warning : Theme.textMuted
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        AdminField {
                                            id: priceField
                                            Layout.preferredWidth: 130
                                            text: row.price !== undefined ? Number(row.price).toFixed(2) : ""
                                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                                        }

                                        ActionButton {
                                            text: "Ціна"
                                            implicitWidth: 96
                                            onClicked: adminModel.updateBookPrice(row.bookId, root.parseNumber(priceField.text, -1))
                                        }

                                        ActionButton {
                                            text: "Видалити"
                                            implicitWidth: 108
                                            borderColor: Theme.error
                                            textColor: Theme.error
                                            hoverColor: Qt.rgba(244 / 255, 67 / 255, 54 / 255, 0.14)
                                            onClicked: adminModel.deleteBook(row.bookId)
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
                        text: root.filteredComments.length + " із " + root.commentsCount
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }
                }

                AdminSearchField {
                    Layout.fillWidth: true
                    placeholderText: "Пошук за книгою, автором або текстом коментаря"
                    text: root.commentsQuery
                    onTextChanged: root.commentsQuery = text
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.borderLight
                }

                Label {
                    Layout.fillWidth: true
                    visible: root.filteredComments.length === 0
                    text: root.commentsCount === 0
                          ? "Коментарів для модерації не знайдено."
                          : "Немає коментарів за поточним фільтром."
                    color: Theme.textSecondary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                ScrollView {
                    id: commentsScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    contentWidth: availableWidth

                    Column {
                        width: commentsScroll.availableWidth
                        spacing: 8

                        Repeater {
                            model: root.filteredComments

                            Rectangle {
                                width: parent.width
                                radius: Theme.radiusSoft
                                color: commentHover.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.015)
                                border.width: 1
                                border.color: Theme.borderLight
                                implicitHeight: Math.max(96, Math.max(commentMainCol.implicitHeight, commentActionCol.implicitHeight) + Theme.spacingM * 2)

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }

                                RowLayout {
                                    id: commentRow
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: Theme.spacingM

                                    ColumnLayout {
                                        id: commentMainCol
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Label {
                                            Layout.fillWidth: true
                                            text: "#" + (modelData.commentId || "") + "  •  " + (modelData.bookTitle || "Книга")
                                            color: Theme.textPrimary
                                            font.family: Theme.fontBody.family
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: (modelData.authorName || "") + "  •  " + (modelData.commentDate || "")
                                            color: Theme.textMuted
                                            font.family: Theme.fontCaption.family
                                            font.pixelSize: 10
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Theme.borderLight
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

                                    ColumnLayout {
                                        id: commentActionCol
                                        property int actionWidth: root.compactLayout ? 88 : 104
                                        Layout.preferredWidth: actionWidth
                                        Layout.minimumWidth: actionWidth
                                        Layout.maximumWidth: actionWidth
                                        Layout.alignment: Qt.AlignTop
                                        spacing: 6

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: commentActionCol.actionWidth
                                            Layout.preferredHeight: 24
                                            radius: 12
                                            border.width: 1
                                            border.color: Theme.borderLight
                                            color: {
                                                var r = Number(modelData.rating || 0)
                                                if (r >= 4) return Qt.rgba(76 / 255, 175 / 255, 80 / 255, 0.18)
                                                if (r >= 3) return Qt.rgba(33 / 255, 150 / 255, 243 / 255, 0.15)
                                                if (r >= 1) return Qt.rgba(255 / 255, 152 / 255, 0 / 255, 0.16)
                                                return Qt.rgba(1, 1, 1, 0.07)
                                            }

                                            Label {
                                                anchors.centerIn: parent
                                                text: "★ " + (modelData.rating !== undefined ? modelData.rating : "-")
                                                color: Theme.textPrimary
                                                font.family: Theme.fontCaption.family
                                                font.pixelSize: 10
                                            }
                                        }

                                        ActionButton {
                                            Layout.alignment: Qt.AlignHCenter
                                            implicitWidth: commentActionCol.actionWidth
                                            text: "Очистити"
                                            buttonHeight: 28
                                            sidePadding: 10
                                            cornerRadius: 12
                                            borderColor: Theme.error
                                            textColor: Theme.error
                                            hoverColor: Qt.rgba(244 / 255, 67 / 255, 54 / 255, 0.14)
                                            onClicked: adminModel.deleteComment(modelData.commentId)
                                        }
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
                            text: root.filteredOrders.length + " із " + root.ordersCount
                            color: Theme.textMuted
                            font.family: Theme.fontCaption.family
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                        }
                    }

                    AdminSearchField {
                        Layout.fillWidth: true
                        placeholderText: "Пошук за ID, клієнтом, адресою або статусом"
                        text: root.ordersQuery
                        onTextChanged: root.ordersQuery = text
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.borderLight
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: root.filteredOrders.length === 0
                        text: root.ordersCount === 0
                              ? "Немає замовлень для відображення."
                              : "Немає замовлень за поточним фільтром."
                        color: Theme.textSecondary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ScrollView {
                        id: ordersScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        contentWidth: availableWidth

                        Column {
                            width: ordersScroll.availableWidth
                            spacing: 8

                            Repeater {
                                model: root.filteredOrders

                                Rectangle {
                                    width: parent.width
                                    radius: Theme.radiusSoft
                                    implicitHeight: Math.max(88, Math.max(orderMainCol.implicitHeight, orderMetaCol.implicitHeight) + Theme.spacingM * 2)
                                    color: orderHover.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.015)
                                    border.width: 1
                                    border.color: Theme.borderLight

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animationFast }
                                    }

                                    RowLayout {
                                        id: orderRow
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingM
                                        spacing: Theme.spacingS

                                        ColumnLayout {
                                            id: orderMainCol
                                            Layout.fillWidth: true
                                            spacing: 5

                                            Label {
                                                Layout.fillWidth: true
                                                text: "#" + (modelData.orderId || "") + "  •  " + (modelData.customerName || "")
                                                color: Theme.textPrimary
                                                font.family: Theme.fontBody.family
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

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 1
                                                color: Theme.borderLight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.lastStatus || "-"
                                                color: Theme.textMuted
                                                font.family: Theme.fontCaption.family
                                                font.pixelSize: 9
                                                font.capitalization: Font.AllUppercase
                                                elide: Text.ElideRight
                                            }
                                        }

                                        ColumnLayout {
                                            id: orderMetaCol
                                            property int metaWidth: root.compactLayout ? 102 : 116
                                            Layout.preferredWidth: metaWidth
                                            Layout.minimumWidth: metaWidth
                                            Layout.maximumWidth: metaWidth
                                            Layout.alignment: Qt.AlignTop
                                            spacing: 6

                                            Rectangle {
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.preferredWidth: orderMetaCol.metaWidth
                                                Layout.preferredHeight: 24
                                                radius: 12
                                                color: Qt.rgba(1, 1, 1, 0.07)
                                                border.width: 1
                                                border.color: Theme.borderLight

                                                Label {
                                                    anchors.centerIn: parent
                                                    text: Number(modelData.totalAmount || 0).toFixed(2) + " UAH"
                                                    color: Theme.textPrimary
                                                    font.family: Theme.fontCaption.family
                                                    font.pixelSize: 9
                                                    font.capitalization: Font.AllUppercase
                                                }
                                            }

                                            Rectangle {
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.preferredWidth: orderMetaCol.metaWidth
                                                Layout.preferredHeight: 28
                                                radius: 14
                                                color: root.orderStatusTheme(modelData.lastStatus).bg
                                                border.width: 1
                                                border.color: root.orderStatusTheme(modelData.lastStatus).border

                                                Label {
                                                    anchors.centerIn: parent
                                                    width: parent.width - 12
                                                    text: modelData.lastStatus || "-"
                                                    color: root.orderStatusTheme(modelData.lastStatus).text
                                                    font.family: Theme.fontCaption.family
                                                    font.pixelSize: 9
                                                    font.capitalization: Font.AllUppercase
                                                    elide: Text.ElideRight
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
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
                        text: root.filteredUsers.length + " із " + root.usersCount
                        visible: !root.compactLayout
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    AdminSearchField {
                        Layout.fillWidth: true
                        placeholderText: "Пошук за ім'ям, email або ID"
                        text: root.usersQuery
                        onTextChanged: root.usersQuery = text
                    }

                    ActionButton {
                        text: root.usersAdminsOnly ? "Усі ролі" : "Лише адміни"
                        implicitWidth: 130
                        borderColor: root.usersAdminsOnly ? Theme.info : Theme.borderLight
                        textColor: root.usersAdminsOnly ? Theme.info : Theme.textPrimary
                        hoverColor: root.usersAdminsOnly
                                   ? Qt.rgba(33 / 255, 150 / 255, 243 / 255, 0.16)
                                   : Qt.rgba(1, 1, 1, 0.08)
                        onClicked: root.usersAdminsOnly = !root.usersAdminsOnly
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.borderLight
                }

                Label {
                    Layout.fillWidth: true
                    visible: root.filteredUsers.length === 0
                    text: root.usersCount === 0
                          ? "Список користувачів порожній."
                          : "Немає користувачів за поточним фільтром."
                    color: Theme.textSecondary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                ScrollView {
                    id: usersScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    contentWidth: availableWidth

                    Column {
                        width: usersScroll.availableWidth
                        spacing: 8

                        Repeater {
                            model: root.filteredUsers

                            Rectangle {
                                width: parent.width
                                radius: Theme.radiusSoft
                                implicitHeight: Math.max(88, Math.max(userMainCol.implicitHeight, userMetaCol.implicitHeight) + Theme.spacingM * 2)
                                color: userHover.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.015)
                                border.width: 1
                                border.color: Theme.borderLight

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }

                                RowLayout {
                                    id: userRow
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: Theme.spacingS

                                    ColumnLayout {
                                        id: userMainCol
                                        Layout.fillWidth: true
                                        spacing: 5

                                        Label {
                                            Layout.fillWidth: true
                                            text: "#" + (modelData.customerId || "") + "  •  " + (modelData.fullName || "")
                                            color: Theme.textPrimary
                                            font.family: Theme.fontBody.family
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.email || ""
                                            color: Theme.textSecondary
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Theme.borderLight
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: (modelData.isAdmin ? "Роль: Адміністратор" : "Роль: Користувач")
                                            color: modelData.isAdmin ? Theme.info : Theme.textMuted
                                            font.family: Theme.fontCaption.family
                                            font.pixelSize: 9
                                            font.capitalization: Font.AllUppercase
                                            elide: Text.ElideRight
                                        }
                                    }

                                    ColumnLayout {
                                        id: userMetaCol
                                        property int metaWidth: root.compactLayout ? 96 : 110
                                        Layout.preferredWidth: metaWidth
                                        Layout.minimumWidth: metaWidth
                                        Layout.maximumWidth: metaWidth
                                        Layout.alignment: Qt.AlignTop
                                        spacing: 6

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: userMetaCol.metaWidth
                                            Layout.preferredHeight: 24
                                            radius: 12
                                            color: Qt.rgba(1, 1, 1, 0.07)
                                            border.width: 1
                                            border.color: Theme.borderLight

                                            Label {
                                                anchors.centerIn: parent
                                                text: (modelData.loyaltyPoints || 0) + " LP"
                                                color: Theme.textPrimary
                                                font.family: Theme.fontCaption.family
                                                font.pixelSize: 9
                                                font.capitalization: Font.AllUppercase
                                            }
                                        }

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: userMetaCol.metaWidth
                                            Layout.preferredHeight: 30
                                            radius: 15
                                            color: Qt.rgba(1, 1, 1, 0.02)
                                            border.width: 1
                                            border.color: Theme.borderLight

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 4

                                                Label {
                                                    text: root.compactLayout ? "A" : "Адмін"
                                                    color: Theme.textSecondary
                                                    font.family: Theme.fontCaption.family
                                                    font.pixelSize: 9
                                                    font.capitalization: Font.AllUppercase
                                                }

                                                Switch {
                                                    id: adminSwitch
                                                    checked: modelData.isAdmin || false
                                                    onToggled: adminModel.setUserAdminRole(modelData.customerId, checked)

                                                    padding: 0
                                                    implicitWidth: 40
                                                    implicitHeight: 22
                                                    Layout.alignment: Qt.AlignVCenter

                                                    indicator: Rectangle {
                                                        implicitWidth: 40
                                                        implicitHeight: 22
                                                        radius: 11
                                                        color: adminSwitch.checked ? Qt.rgba(76 / 255, 175 / 255, 80 / 255, 0.35) : Qt.rgba(1, 1, 1, 0.1)
                                                        border.width: 1
                                                        border.color: adminSwitch.checked ? Theme.success : Theme.borderLight

                                                        Rectangle {
                                                            width: 16
                                                            height: 16
                                                            radius: 8
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
