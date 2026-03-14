import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

ScrollView {
    id: root

    property var selectedOrderDetails: emptyOrderDetails()
    property string orderDetailsError: ""
    property bool detailsPanelOpen: false
    property var detailsHost: Overlay.overlay ? Overlay.overlay : root
    property int detailsPanelWidth: Math.min(Theme.filterPanelWidth + 60,
                                             Math.max(340, (detailsHost ? detailsHost.width : root.width) - 40))
    property int detailsPanelInnerPadding: detailsPanelWidth > 420 ? Theme.spacingL : Theme.spacingM
    property int detailMetricColumns: detailsPanelWidth > 430 ? 3 : 2
    property var trackingMeta: emptyTrackingMeta()
    property var trackingStages: []

    function emptyOrderDetails() {
        return {
            orderId: 0,
            orderDate: "",
            orderDateIso: "",
            orderDateMs: 0,
            totalAmount: 0,
            status: "",
            shippingAddress: "",
            paymentMethod: "",
            statuses: [],
            items: []
        }
    }

    function emptyTrackingMeta() {
        return {
            stages: [],
            progress: 0,
            currentStageIndex: 0,
            currentStatus: "",
            trackingNumber: "",
            isCanceled: false,
            isDelivered: false,
            etaTitle: "ETA: —",
            etaHint: "Оцінка з'явиться після оновлення статусів"
        }
    }

    function formatMoney(value) {
        var amount = Number(value)
        if (!isFinite(amount))
            amount = 0
        return amount.toFixed(2) + " грн"
    }

    function detailItemsCount() {
        return (root.selectedOrderDetails.items || []).length
    }

    function detailStatusesCount() {
        return (root.selectedOrderDetails.statuses || []).length
    }

    function trackingProgressPercent() {
        var progress = Number(root.trackingMeta.progress || 0)
        if (!isFinite(progress))
            progress = 0
        progress = Math.max(0, Math.min(1, progress))
        return Math.round(progress * 100)
    }

    function statusBadgeColor(status) {
        var normalized = (status || "").toLowerCase()
        if (normalized.indexOf("cancel") !== -1 || normalized.indexOf("скас") !== -1)
            return Theme.error
        if (normalized.indexOf("deliver") !== -1 || normalized.indexOf("викон") !== -1 || normalized.indexOf("достав") !== -1 || normalized.indexOf("отрим") !== -1)
            return Theme.success
        if (normalized.indexOf("ship") !== -1 || normalized.indexOf("дороз") !== -1 || normalized.indexOf("відправ") !== -1)
            return Theme.info
        if (normalized.indexOf("оплач") !== -1 || normalized.indexOf("paid") !== -1 || normalized.indexOf("confirm") !== -1 || normalized.indexOf("нов") !== -1 || normalized.indexOf("оброб") !== -1)
            return Theme.warning
        return Theme.textSecondary
    }

    function pad2(value) {
        var num = Number(value)
        if (!isFinite(num))
            num = 0
        num = Math.floor(Math.abs(num))
        return num < 10 ? "0" + num : String(num)
    }

    function parseDateTimeText(value) {
        var match = /^(\d{2})\.(\d{2})\.(\d{4})(?:\s+(\d{2}):(\d{2}))?$/.exec((value || "").trim())
        if (!match)
            return 0

        var day = Number(match[1])
        var month = Number(match[2]) - 1
        var year = Number(match[3])
        var hour = Number(match[4] || 0)
        var minute = Number(match[5] || 0)
        var date = new Date(year, month, day, hour, minute, 0, 0)
        var ms = date.getTime()
        return isFinite(ms) ? ms : 0
    }

    function parseTimestamp(rawValue) {
        if (rawValue === undefined || rawValue === null)
            return 0

        if (typeof rawValue === "number") {
            return isFinite(rawValue) && rawValue > 0 ? rawValue : 0
        }

        if (typeof rawValue === "string") {
            var text = rawValue.trim()
            if (text.length === 0)
                return 0

            var numeric = Number(text)
            if (isFinite(numeric) && numeric > 0)
                return numeric

            var nativeParsed = Date.parse(text)
            if (!isNaN(nativeParsed))
                return nativeParsed

            return parseDateTimeText(text)
        }

        var fallback = Number(rawValue)
        return isFinite(fallback) && fallback > 0 ? fallback : 0
    }

    function formatDateTimeMs(ms) {
        var parsed = parseTimestamp(ms)
        if (parsed <= 0)
            return "—"

        var date = new Date(parsed)
        return pad2(date.getDate()) + "." + pad2(date.getMonth() + 1) + "." + date.getFullYear() +
                " " + pad2(date.getHours()) + ":" + pad2(date.getMinutes())
    }

    function formatDateShortMs(ms) {
        var parsed = parseTimestamp(ms)
        if (parsed <= 0)
            return "—"

        var date = new Date(parsed)
        return pad2(date.getDate()) + "." + pad2(date.getMonth() + 1)
    }

    function normalizeStatusKey(status) {
        var normalized = (status || "").toLowerCase()

        if (normalized.indexOf("скас") !== -1 || normalized.indexOf("cancel") !== -1 || normalized.indexOf("відмін") !== -1)
            return "canceled"

        if (normalized.indexOf("доставлен") !== -1 || normalized.indexOf("отрим") !== -1 || normalized.indexOf("викон") !== -1 || normalized.indexOf("complete") !== -1)
            return "delivered"

        if (normalized.indexOf("відправ") !== -1 || normalized.indexOf("дороз") !== -1 || normalized.indexOf("ship") !== -1 || normalized.indexOf("transit") !== -1 || normalized.indexOf("кур'єр") !== -1 || normalized.indexOf("курьер") !== -1)
            return "shipped"

        if (normalized.indexOf("комплект") !== -1 || normalized.indexOf("оброб") !== -1 || normalized.indexOf("processing") !== -1 || normalized.indexOf("pack") !== -1 || normalized.indexOf("збір") !== -1)
            return "processing"

        if (normalized.indexOf("підтвер") !== -1 || normalized.indexOf("confirm") !== -1 || normalized.indexOf("оплач") !== -1 || normalized.indexOf("paid") !== -1)
            return "confirmed"

        if (normalized.indexOf("нов") !== -1 || normalized.indexOf("create") !== -1 || normalized.indexOf("pending") !== -1)
            return "created"

        return "unknown"
    }

    function stageIndexForStatusKey(statusKey) {
        if (statusKey === "created")
            return 0
        if (statusKey === "confirmed")
            return 1
        if (statusKey === "processing")
            return 2
        if (statusKey === "shipped")
            return 3
        if (statusKey === "delivered")
            return 4
        return -1
    }

    function estimateEtaWindow(currentStage, stageTimes, orderCreatedMs) {
        var dayMs = 24 * 60 * 60 * 1000
        var fromDays = 3
        var toDays = 6
        var baseMs = orderCreatedMs > 0 ? orderCreatedMs : Date.now()

        if (currentStage >= 3 && stageTimes[3]) {
            baseMs = stageTimes[3]
            fromDays = 1
            toDays = 2
        } else if (currentStage >= 2 && stageTimes[2]) {
            baseMs = stageTimes[2]
            fromDays = 1
            toDays = 3
        } else if (currentStage >= 1 && stageTimes[1]) {
            baseMs = stageTimes[1]
            fromDays = 2
            toDays = 4
        }

        return {
            from: baseMs + fromDays * dayMs,
            to: baseMs + toDays * dayMs
        }
    }

    function buildTrackingMeta(details) {
        var templates = [
            { title: "Створено", hint: "Замовлення зареєстровано" },
            { title: "Підтверджено", hint: "Оплату та дані перевірено" },
            { title: "Комплектація", hint: "Готуємо посилку до відправки" },
            { title: "В дорозі", hint: "Передано службі доставки" },
            { title: "Доставлено", hint: "Замовлення отримано" }
        ]

        var meta = {
            stages: [],
            progress: 0,
            currentStageIndex: 0,
            currentStatus: details && details.status ? details.status : "",
            trackingNumber: "",
            isCanceled: false,
            isDelivered: false,
            etaTitle: "ETA: —",
            etaHint: "Оцінка з'явиться після оновлення статусів"
        }

        if (!details || !details.orderId)
            return meta

        var statuses = details.statuses || []
        var stageTimes = {}
        var reachedStage = 0
        var latestStatusMs = parseTimestamp(details.orderDateMs || details.orderDateIso || details.orderDate)

        for (var i = 0; i < statuses.length; ++i) {
            var eventItem = statuses[i] || {}
            var statusText = eventItem.status || ""
            var eventMs = parseTimestamp(eventItem.statusDateMs || eventItem.statusDateIso || eventItem.statusDate)

            if (eventMs > latestStatusMs) {
                latestStatusMs = eventMs
                meta.currentStatus = statusText
            }

            if (eventItem.trackingNumber && String(eventItem.trackingNumber).trim().length > 0)
                meta.trackingNumber = String(eventItem.trackingNumber).trim()

            var statusKey = normalizeStatusKey(statusText)
            if (statusKey === "canceled") {
                meta.isCanceled = true
                continue
            }

            var stageIndex = stageIndexForStatusKey(statusKey)
            if (stageIndex >= 0) {
                reachedStage = Math.max(reachedStage, stageIndex)
                if (!stageTimes[stageIndex] && eventMs > 0)
                    stageTimes[stageIndex] = eventMs

                if (statusKey === "delivered")
                    meta.isDelivered = true
            }
        }

        var orderCreatedMs = parseTimestamp(details.orderDateMs || details.orderDateIso || details.orderDate)
        if (!stageTimes[0] && orderCreatedMs > 0)
            stageTimes[0] = orderCreatedMs

        if (meta.isDelivered)
            reachedStage = templates.length - 1

        meta.currentStageIndex = reachedStage
        meta.progress = Math.max(0, Math.min(1, (reachedStage + 1) / templates.length))

        for (var stagePos = 0; stagePos < templates.length; ++stagePos) {
            var stageDone = stagePos < reachedStage || (meta.isDelivered && stagePos === templates.length - 1)
            var stageActive = !meta.isCanceled && ((meta.isDelivered && stagePos === templates.length - 1) || (!meta.isDelivered && stagePos === reachedStage))
            var stageMs = stageTimes[stagePos] || 0

            meta.stages.push({
                title: templates[stagePos].title,
                hint: templates[stagePos].hint,
                done: stageDone,
                active: stageActive,
                pending: !stageDone && !stageActive,
                timestampMs: stageMs,
                dateText: stageMs > 0 ? formatDateTimeMs(stageMs) : (stagePos > reachedStage ? "Очікується" : "—")
            })
        }

        if (meta.isCanceled) {
            meta.etaTitle = "Доставку скасовано"
            meta.etaHint = meta.currentStatus && meta.currentStatus.length > 0
                    ? ("Останній статус: " + meta.currentStatus)
                    : "Оновіть статус в адмін-панелі для повторної обробки"
            return meta
        }

        if (meta.isDelivered) {
            var deliveredMs = stageTimes[templates.length - 1] || latestStatusMs
            meta.etaTitle = "Доставлено"
            meta.etaHint = deliveredMs > 0 ? ("Факт: " + formatDateTimeMs(deliveredMs)) : "Замовлення завершене"
            return meta
        }

        var etaWindow = estimateEtaWindow(reachedStage, stageTimes, orderCreatedMs)
        meta.etaTitle = "ETA: " + formatDateShortMs(etaWindow.from) + " – " + formatDateShortMs(etaWindow.to)
        meta.etaHint = "Оцінка оновлюється після кожного нового статусу"

        return meta
    }

    function openOrderDetails(orderId) {
        orderDetailsError = ""
        var details = ordersModel.getOrderDetails(orderId)
        if (!details || !details.orderId) {
            orderDetailsError = "Не вдалося завантажити деталі замовлення"
            return
        }

        selectedOrderDetails = details
        trackingMeta = buildTrackingMeta(details)
        trackingStages = trackingMeta.stages || []
        detailsPanelOpen = true
    }

    function closeOrderDetailsPanel() {
        detailsPanelOpen = false
    }

    clip: false
    contentWidth: availableWidth
    contentHeight: contentColumn.implicitHeight
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Component.onCompleted: {
        if (appContext && appContext.loggedIn) {
            console.log("OrdersPage loaded, loading orders...")
            ordersModel.loadOrders()
        }
    }

    Connections {
        target: appContext
        function onLoggedInChanged() {
            if (appContext && appContext.loggedIn) {
                ordersModel.loadOrders()
            } else {
                selectedOrderDetails = emptyOrderDetails()
                trackingMeta = emptyTrackingMeta()
                trackingStages = []
                detailsPanelOpen = false
            }
        }
    }

    ColumnLayout {
        id: contentColumn
        width: Math.max(0, root.availableWidth - (root.detailsPanelOpen ? root.detailsPanelWidth : 0))
        spacing: 0

        Behavior on width {
            NumberAnimation { duration: Theme.animationSlow; easing.type: Easing.OutCubic }
        }

        Item { Layout.preferredHeight: 20 }

        Rectangle {
            visible: !(appContext && appContext.loggedIn)
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
            Layout.preferredHeight: 220
            color: Qt.rgba(1, 1, 1, 0.02)
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
                    text: "Історія замовлень доступна після входу"
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 28
                }

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "Увійдіть у профіль, щоб переглядати ваші замовлення та статуси доставки."
                    color: Theme.textSecondary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 13
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Перейти в профіль"
                    onClicked: appContext.navigateTo("profile")
                }
            }
        }

        ColumnLayout {
            visible: appContext && appContext.loggedIn
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 6
                spacing: 0

                Label {
                    Layout.preferredWidth: 90
                    text: "ID"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }

                Label {
                    Layout.preferredWidth: 180
                    text: "\u0414\u0430\u0442\u0430"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }

                Label {
                    Layout.fillWidth: true
                    text: "\u0422\u043e\u0432\u0430\u0440\u0438"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }

                Label {
                    Layout.preferredWidth: 160
                    text: "\u0421\u0443\u043c\u0430"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }

                Label {
                    Layout.preferredWidth: 160
                    text: "\u0421\u0442\u0430\u0442\u0443\u0441"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderLight
            }

            Label {
                Layout.topMargin: 22
                visible: ordersModel.count === 0
                text: "\u041d\u0435\u043c\u0430\u0454 \u0437\u0430\u043c\u043e\u0432\u043b\u0435\u043d\u044c"
                color: Theme.textSecondary
                font.pixelSize: 14
            }

            Repeater {
                model: ordersModel

                Rectangle {
                    Layout.fillWidth: true
                    height: 78
                    color: orderArea.containsMouse ? Qt.rgba(1, 1, 1, 0.02) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Label {
                            Layout.preferredWidth: 90
                            text: "#" + model.orderId
                            color: Theme.textSecondary
                            font.pixelSize: 14
                        }

                        Label {
                            Layout.preferredWidth: 180
                            text: model.orderDate
                            color: Theme.textSecondary
                            font.pixelSize: 14
                        }

                        Label {
                            Layout.fillWidth: true
                            text: model.itemCount + "\u00a0\u0442\u043e\u0432."
                            color: Theme.textSecondary
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.preferredWidth: 160
                            text: Number(model.totalAmount).toFixed(2) + " \u0433\u0440\u043d"
                            color: Theme.textPrimary
                            font.pixelSize: 14
                        }

                        Label {
                            Layout.preferredWidth: 160
                            text: (model.status || "").toUpperCase()
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            font.letterSpacing: 1
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: orderArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openOrderDetails(model.orderId)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Theme.borderLight
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Theme.spacingXXL }
    }

    Rectangle {
        id: detailsOverlay
        parent: root.detailsHost
        anchors.fill: parent
        color: "#000000"
        opacity: root.detailsPanelOpen ? 0.6 : 0
        visible: root.detailsPanelOpen
        z: 5

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationSmooth }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.detailsPanelOpen
            onClicked: root.closeOrderDetailsPanel()
        }
    }

    Rectangle {
        id: detailsPanel
        parent: root.detailsHost
        z: 10
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.detailsPanelWidth
        x: root.detailsPanelOpen ? parent.width - width : parent.width

        Behavior on x {
            NumberAnimation { duration: Theme.animationSlow; easing.type: Easing.OutCubic }
        }

        visible: root.detailsPanelOpen
        enabled: root.detailsPanelOpen

        color: Theme.glassPanel
        border.color: Theme.borderLight
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.borderLight
        }

        ScrollView {
            id: detailsScroll
            anchors.fill: parent
            anchors.margins: root.detailsPanelInnerPadding
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            contentWidth: availableWidth

            ColumnLayout {
                id: detailsContent
                width: detailsScroll.availableWidth
                spacing: Theme.spacingL

                Rectangle {
                    Layout.fillWidth: true
                    radius: Theme.radiusSoft
                    color: Qt.rgba(1, 1, 1, 0.022)
                    border.width: 1
                    border.color: Theme.borderLight
                    implicitHeight: heroContent.implicitHeight + root.detailsPanelInnerPadding * 2

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.055) }
                            GradientStop { position: 0.48; color: Qt.rgba(1, 1, 1, 0.015) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        }
                    }

                    ColumnLayout {
                        id: heroContent
                        anchors.fill: parent
                        anchors.margins: root.detailsPanelInnerPadding
                        spacing: Theme.spacingM

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingM

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: "Деталі замовлення"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontDisplayItalic.family
                                    font.pixelSize: 28
                                    font.italic: true
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: "Уся інформація про оплату, доставку та склад замовлення в одному місці."
                                    color: Theme.textSecondary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 21
                                color: closeDetailsArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.025)
                                border.width: 1
                                border.color: closeDetailsArea.containsMouse ? Theme.borderHover : Theme.borderLight

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: closeDetailsArea.containsMouse ? Theme.textSecondary : Theme.textPrimary
                                    font.pixelSize: 20
                                }

                                MouseArea {
                                    id: closeDetailsArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.closeOrderDetailsPanel()
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.borderLight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingM

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    visible: Number(root.selectedOrderDetails.orderId || 0) > 0
                                    text: "#" + root.selectedOrderDetails.orderId
                                    color: Theme.textPrimary
                                    font.family: Theme.fontDisplay.family
                                    font.pixelSize: 32
                                }

                                Label {
                                    visible: (root.selectedOrderDetails.orderDate || "").length > 0
                                    text: "Створено " + (root.selectedOrderDetails.orderDate || "")
                                    color: Theme.textSecondary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 12
                                }
                            }

                            Rectangle {
                                visible: (root.selectedOrderDetails.status || "").length > 0
                                radius: Theme.radiusPill
                                color: Qt.rgba(1, 1, 1, 0.04)
                                border.width: 1
                                border.color: root.statusBadgeColor(root.selectedOrderDetails.status)
                                implicitWidth: heroStatusLabel.implicitWidth + Theme.spacingL
                                implicitHeight: 36

                                Label {
                                    id: heroStatusLabel
                                    anchors.centerIn: parent
                                    text: (root.selectedOrderDetails.status || "—").toUpperCase()
                                    color: root.statusBadgeColor(root.selectedOrderDetails.status)
                                    font.family: Theme.fontCaption.family
                                    font.pixelSize: 10
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 1.1
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: root.detailMetricColumns
                            rowSpacing: Theme.spacingS
                            columnSpacing: Theme.spacingS

                            Rectangle {
                                Layout.fillWidth: true
                                radius: Theme.radiusSoft
                                color: Qt.rgba(1, 1, 1, 0.03)
                                border.width: 1
                                border.color: Theme.borderLight
                                implicitHeight: amountCardContent.implicitHeight + Theme.spacingM * 2

                                ColumnLayout {
                                    id: amountCardContent
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: 4

                                    Label {
                                        text: "Сума"
                                        color: Theme.textMuted
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 1
                                    }

                                    Label {
                                        text: root.formatMoney(root.selectedOrderDetails.totalAmount)
                                        color: Theme.textPrimary
                                        font.family: Theme.fontDisplay.family
                                        font.pixelSize: 20
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: Theme.radiusSoft
                                color: Qt.rgba(1, 1, 1, 0.03)
                                border.width: 1
                                border.color: Theme.borderLight
                                implicitHeight: paymentCardContent.implicitHeight + Theme.spacingM * 2

                                ColumnLayout {
                                    id: paymentCardContent
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: 4

                                    Label {
                                        text: "Оплата"
                                        color: Theme.textMuted
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 1
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: root.selectedOrderDetails.paymentMethod || "—"
                                        color: Theme.textPrimary
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 14
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: Theme.radiusSoft
                                color: Qt.rgba(1, 1, 1, 0.03)
                                border.width: 1
                                border.color: Theme.borderLight
                                implicitHeight: metaCardContent.implicitHeight + Theme.spacingM * 2

                                ColumnLayout {
                                    id: metaCardContent
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: 4

                                    Label {
                                        text: "Позиції та етапи"
                                        color: Theme.textMuted
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 1
                                    }

                                    Label {
                                        text: root.detailItemsCount() + " товарів"
                                        color: Theme.textPrimary
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 14
                                    }

                                    Label {
                                        text: root.detailStatusesCount() + " статусів"
                                        color: Theme.textSecondary
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: Theme.radiusSoft
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.width: 1
                            border.color: Theme.borderLight
                            implicitHeight: shippingCardContent.implicitHeight + Theme.spacingM * 2

                            ColumnLayout {
                                id: shippingCardContent
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: 6

                                Label {
                                    text: "Адреса доставки"
                                    color: Theme.textMuted
                                    font.family: Theme.fontCaption.family
                                    font.pixelSize: 10
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 1
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: root.selectedOrderDetails.shippingAddress || "—"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 14
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    Label {
                        text: "Трекінг доставки"
                        color: Theme.textPrimary
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 24
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: root.trackingMeta.isCanceled ? "Доставку скасовано" : (root.trackingProgressPercent() + "% маршруту")
                        color: root.trackingMeta.isCanceled ? Theme.error : Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: Theme.radiusSoft
                    color: Qt.rgba(1, 1, 1, 0.022)
                    border.width: 1
                    border.color: Theme.borderLight
                    implicitHeight: trackingSummaryContent.implicitHeight + Theme.spacingL * 2

                    ColumnLayout {
                        id: trackingSummaryContent
                        anchors.fill: parent
                        anchors.margins: Theme.spacingL
                        spacing: Theme.spacingM

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingS

                            Rectangle {
                                radius: Theme.radiusPill
                                color: Qt.rgba(1, 1, 1, 0.035)
                                border.width: 1
                                border.color: root.trackingMeta.isCanceled ? Theme.error : root.statusBadgeColor(root.trackingMeta.currentStatus || root.selectedOrderDetails.status)
                                implicitWidth: trackingStatusLabel.implicitWidth + Theme.spacingL
                                implicitHeight: 34

                                Label {
                                    id: trackingStatusLabel
                                    anchors.centerIn: parent
                                    text: (root.trackingMeta.currentStatus || root.selectedOrderDetails.status || "—").toUpperCase()
                                    color: root.trackingMeta.isCanceled ? Theme.error : root.statusBadgeColor(root.trackingMeta.currentStatus || root.selectedOrderDetails.status)
                                    font.family: Theme.fontCaption.family
                                    font.pixelSize: 10
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 1
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                radius: Theme.radiusPill
                                color: Qt.rgba(1, 1, 1, 0.03)
                                border.width: 1
                                border.color: Theme.borderLight
                                implicitWidth: trackingPercentLabel.implicitWidth + Theme.spacingM
                                implicitHeight: 32

                                Label {
                                    id: trackingPercentLabel
                                    anchors.centerIn: parent
                                    text: root.trackingMeta.isCanceled ? "STOP" : (root.trackingProgressPercent() + "%")
                                    color: root.trackingMeta.isCanceled ? Theme.error : Theme.textPrimary
                                    font.family: Theme.fontCaption.family
                                    font.pixelSize: 10
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 1
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 8
                            radius: 4
                            color: Qt.rgba(1, 1, 1, 0.06)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(0, Math.min(parent.width, parent.width * (root.trackingMeta.progress || 0)))
                                height: parent.height
                                radius: parent.radius
                                color: root.trackingMeta.isCanceled ? Theme.error : Theme.accentWhite

                                Behavior on width {
                                    NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: detailsContent.width > 400 ? 2 : 1
                            columnSpacing: Theme.spacingM
                            rowSpacing: Theme.spacingS

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: root.trackingMeta.etaTitle || "ETA: —"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 14
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: root.trackingMeta.etaHint || ""
                                    color: Theme.textSecondary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: "Трек-номер"
                                    color: Theme.textMuted
                                    font.family: Theme.fontCaption.family
                                    font.pixelSize: 10
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 1
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: (root.trackingMeta.trackingNumber || "").length > 0 ? root.trackingMeta.trackingNumber : "Ще не призначено"
                                    color: (root.trackingMeta.trackingNumber || "").length > 0 ? Theme.textPrimary : Theme.textSecondary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: root.trackingStages || []

                    Rectangle {
                        id: timelineStageCard
                        Layout.fillWidth: true
                        radius: Theme.radiusSoft
                        color: stageActive
                               ? Qt.rgba(1, 1, 1, 0.05)
                               : (stageDone ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.015))
                        border.width: 1
                        border.color: (stageDone || stageActive) ? stageColor : Theme.borderLight
                        implicitHeight: stageContent.implicitHeight + Theme.spacingM * 2
                        property bool stageDone: modelData.done === true
                        property bool stageActive: modelData.active === true
                        property color stageColor: root.trackingMeta.isCanceled ? Theme.error : Theme.accentWhite

                        RowLayout {
                            id: stageContent
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                color: timelineStageCard.stageDone ? timelineStageCard.stageColor : "transparent"
                                border.width: 1
                                border.color: (timelineStageCard.stageDone || timelineStageCard.stageActive)
                                              ? timelineStageCard.stageColor
                                              : Theme.borderLight

                                Label {
                                    anchors.centerIn: parent
                                    text: timelineStageCard.stageDone ? "✓" : (timelineStageCard.stageActive ? "•" : "")
                                    color: timelineStageCard.stageDone ? Theme.bgBody : timelineStageCard.stageColor
                                    font.pixelSize: timelineStageCard.stageDone ? 11 : 18
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingS

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.title || "Етап"
                                        color: (timelineStageCard.stageDone || timelineStageCard.stageActive) ? Theme.textPrimary : Theme.textSecondary
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        radius: Theme.radiusPill
                                        color: Qt.rgba(1, 1, 1, 0.03)
                                        border.width: 1
                                        border.color: (timelineStageCard.stageDone || timelineStageCard.stageActive)
                                                      ? timelineStageCard.stageColor
                                                      : Theme.borderLight
                                        implicitWidth: stageStateLabel.implicitWidth + Theme.spacingM
                                        implicitHeight: 26

                                        Label {
                                            id: stageStateLabel
                                            anchors.centerIn: parent
                                            text: timelineStageCard.stageDone
                                                  ? "Готово"
                                                  : (timelineStageCard.stageActive ? "Зараз" : "Далі")
                                            color: (timelineStageCard.stageDone || timelineStageCard.stageActive)
                                                   ? timelineStageCard.stageColor
                                                   : Theme.textMuted
                                            font.family: Theme.fontCaption.family
                                            font.pixelSize: 9
                                            font.capitalization: Font.AllUppercase
                                            font.letterSpacing: 1
                                        }
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.hint || ""
                                    color: Theme.textMuted
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.dateText || "—"
                                    color: (timelineStageCard.stageDone || timelineStageCard.stageActive) ? Theme.textSecondary : Theme.textMuted
                                    font.family: Theme.fontCaption.family
                                    font.pixelSize: 10
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.8
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.trackingMeta.isCanceled === true
                    Layout.fillWidth: true
                    radius: Theme.radiusSoft
                    color: Qt.rgba(244 / 255, 67 / 255, 54 / 255, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(244 / 255, 67 / 255, 54 / 255, 0.45)
                    implicitHeight: canceledLabel.implicitHeight + Theme.spacingM * 2

                    Label {
                        id: canceledLabel
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        text: "Замовлення скасовано. ETA недоступне до повторного підтвердження."
                        color: Theme.error
                        wrapMode: Text.WordWrap
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    Label {
                        text: "Події статусів"
                        color: Theme.textPrimary
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 24
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: root.detailStatusesCount() > 0 ? (root.detailStatusesCount() + " записів") : "Без оновлень"
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }
                }

                Repeater {
                    model: root.selectedOrderDetails.statuses || []

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Theme.radiusSoft
                        color: Qt.rgba(1, 1, 1, 0.02)
                        border.width: 1
                        border.color: Theme.borderLight
                        implicitHeight: statusCardContent.implicitHeight + Theme.spacingM * 2

                        ColumnLayout {
                            id: statusCardContent
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingS

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.status || "—"
                                    color: root.statusBadgeColor(modelData.status)
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 13
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.8
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: (modelData.trackingNumber || "").length > 0
                                    radius: Theme.radiusPill
                                    color: Qt.rgba(1, 1, 1, 0.028)
                                    border.width: 1
                                    border.color: Theme.borderLight
                                    implicitWidth: trackingInlineLabel.implicitWidth + Theme.spacingM
                                    implicitHeight: 26

                                    Label {
                                        id: trackingInlineLabel
                                        anchors.centerIn: parent
                                        text: "ТРЕК " + modelData.trackingNumber
                                        color: Theme.textSecondary
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 9
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 1
                                    }
                                }
                            }

                            Label {
                                text: root.formatDateTimeMs(root.parseTimestamp(modelData.statusDateMs || modelData.statusDateIso || modelData.statusDate))
                                color: Theme.textMuted
                                font.family: Theme.fontBody.family
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                Label {
                    visible: (root.selectedOrderDetails.statuses || []).length === 0
                    text: "Статуси ще не оновлювались"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    Label {
                        text: "Книги"
                        color: Theme.textPrimary
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 24
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: root.detailItemsCount() > 0 ? (root.detailItemsCount() + " позицій") : "Порожньо"
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }
                }

                Repeater {
                    model: root.selectedOrderDetails.items || []

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Theme.radiusSoft
                        color: Qt.rgba(1, 1, 1, 0.02)
                        border.width: 1
                        border.color: Theme.borderLight
                        implicitHeight: itemCardContent.implicitHeight + Theme.spacingM * 2

                        ColumnLayout {
                            id: itemCardContent
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingS

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.bookTitle || "Без назви"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    radius: Theme.radiusPill
                                    color: Qt.rgba(1, 1, 1, 0.03)
                                    border.width: 1
                                    border.color: Theme.borderLight
                                    implicitWidth: quantityLabel.implicitWidth + Theme.spacingM
                                    implicitHeight: 28

                                    Label {
                                        id: quantityLabel
                                        anchors.centerIn: parent
                                        text: "x" + (modelData.quantity || 0)
                                        color: Theme.textSecondary
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 1
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingS

                                Label {
                                    text: root.formatMoney(modelData.pricePerUnit)
                                    color: Theme.textSecondary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 12
                                }

                                Label {
                                    text: "за одиницю"
                                    color: Theme.textMuted
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 12
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: root.formatMoney(Number(modelData.pricePerUnit || 0) * Number(modelData.quantity || 0))
                                    color: Theme.textPrimary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                Label {
                    visible: (root.selectedOrderDetails.items || []).length === 0
                    text: "Для цього замовлення не знайдено позицій"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                Item { Layout.preferredHeight: Theme.spacingM }
            }
        }
    }

    Label {
        visible: root.orderDetailsError.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacingXL
        text: root.orderDetailsError
        color: Theme.error
        font.family: Theme.fontBody.family
        font.pixelSize: 12
    }
}
