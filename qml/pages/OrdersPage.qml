import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

ScrollView {
    id: root

    property var selectedOrderDetails: ({})
    property string orderDetailsError: ""
    property bool detailsPanelOpen: false
    property var detailsHost: Overlay.overlay ? Overlay.overlay : root
    property int detailsPanelWidth: Math.min(Theme.filterPanelWidth,
                                             Math.max(320, (detailsHost ? detailsHost.width : root.width) - 40))

    function formatMoney(value) {
        var amount = Number(value)
        if (!isFinite(amount))
            amount = 0
        return amount.toFixed(2) + " грн"
    }

    function statusBadgeColor(status) {
        var normalized = (status || "").toLowerCase()
        if (normalized.indexOf("cancel") !== -1 || normalized.indexOf("скас") !== -1)
            return Theme.error
        if (normalized.indexOf("deliver") !== -1 || normalized.indexOf("викон") !== -1 || normalized.indexOf("достав") !== -1)
            return Theme.success
        return Theme.textSecondary
    }

    function openOrderDetails(orderId) {
        orderDetailsError = ""
        var details = ordersModel.getOrderDetails(orderId)
        if (!details || !details.orderId) {
            orderDetailsError = "Не вдалося завантажити деталі замовлення"
            return
        }

        selectedOrderDetails = details
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
                selectedOrderDetails = ({})
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
            anchors.margins: Theme.spacingL
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            contentWidth: availableWidth

            ColumnLayout {
                id: detailsContent
                width: detailsScroll.availableWidth
                spacing: Theme.spacingL

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Деталі замовлення"
                        color: Theme.textPrimary
                        font.family: Theme.fontDisplayItalic.family
                        font.pixelSize: 28
                        font.italic: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: closeDetailsArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

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

                Label {
                    visible: root.selectedOrderDetails.orderId
                    text: "#" + root.selectedOrderDetails.orderId
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 26
                }

                Label {
                    visible: root.selectedOrderDetails.orderDate
                    text: root.selectedOrderDetails.orderDate || ""
                    color: Theme.textSecondary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                }

                Rectangle {
                    visible: root.selectedOrderDetails.status
                    radius: Theme.radiusRound
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.width: 1
                    border.color: root.statusBadgeColor(root.selectedOrderDetails.status)
                    implicitWidth: statusBadgeLabel.implicitWidth + Theme.spacingL
                    implicitHeight: 34

                    Label {
                        id: statusBadgeLabel
                        anchors.centerIn: parent
                        text: (root.selectedOrderDetails.status || "—").toUpperCase()
                        color: root.statusBadgeColor(root.selectedOrderDetails.status)
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Theme.spacingM
                    rowSpacing: Theme.spacingS

                    Label {
                        text: "Сума"
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                    }
                    Label {
                        text: root.formatMoney(root.selectedOrderDetails.totalAmount)
                        color: Theme.textPrimary
                        font.pixelSize: 13
                    }

                    Label {
                        text: "Оплата"
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                    }
                    Label {
                        text: root.selectedOrderDetails.paymentMethod || "—"
                        color: Theme.textSecondary
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: "Адреса"
                        color: Theme.textMuted
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                    }
                    Label {
                        text: root.selectedOrderDetails.shippingAddress || "—"
                        color: Theme.textSecondary
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderLight
                }

                Label {
                    text: "Книги"
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                }

                Repeater {
                    model: root.selectedOrderDetails.items || []

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Theme.radiusSoft
                        color: Qt.rgba(1, 1, 1, 0.02)
                        border.width: 1
                        border.color: Theme.borderLight
                        implicitHeight: 70

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            anchors.topMargin: Theme.spacingS
                            anchors.bottomMargin: Theme.spacingS
                            spacing: 4

                            Label {
                                Layout.fillWidth: true
                                text: modelData.bookTitle || "Без назви"
                                color: Theme.textPrimary
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingS

                                Label {
                                    text: "x" + (modelData.quantity || 0)
                                    color: Theme.textSecondary
                                    font.pixelSize: 12
                                }

                                Label {
                                    text: root.formatMoney(modelData.pricePerUnit)
                                    color: Theme.textSecondary
                                    font.pixelSize: 12
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: root.formatMoney(Number(modelData.pricePerUnit || 0) * Number(modelData.quantity || 0))
                                    color: Theme.textPrimary
                                    font.pixelSize: 12
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

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderLight
                }

                Label {
                    text: "Історія статусів"
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                }

                Repeater {
                    model: root.selectedOrderDetails.statuses || []

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Theme.radiusSoft
                        color: Qt.rgba(1, 1, 1, 0.02)
                        border.width: 1
                        border.color: Theme.borderLight
                        implicitHeight: 64

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            anchors.topMargin: Theme.spacingS
                            anchors.bottomMargin: Theme.spacingS
                            spacing: 3

                            Label {
                                Layout.fillWidth: true
                                text: modelData.status || "—"
                                color: root.statusBadgeColor(modelData.status)
                                font.pixelSize: 13
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.8
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingS

                                Label {
                                    text: modelData.statusDate || ""
                                    color: Theme.textMuted
                                    font.pixelSize: 12
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    visible: modelData.trackingNumber && modelData.trackingNumber.length > 0
                                    text: "Трек: " + modelData.trackingNumber
                                    color: Theme.textSecondary
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
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
