import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

ScrollView {
    id: root

    property bool checkoutStep: false
    property string checkoutMessage: ""
    property bool checkoutError: false
    property string liqPayCheckoutUrl: ""
    property string pendingCheckoutAddress: ""
    property bool compactCheckout: root.availableWidth < 980
    property bool shippingAddressTouched: false

    function validateShippingAddress(value) {
        var address = (value || "").trim()
        if (address.length === 0)
            return "Вкажіть адресу доставки"
        if (address.length < 8)
            return "Адреса занадто коротка"
        if (address.length > 180)
            return "Адреса занадто довга"
        if (!/[A-Za-zА-Яа-яІіЇїЄєҐґ]/.test(address))
            return "Адреса має містити назву вулиці"
        if (!/[0-9]/.test(address))
            return "Вкажіть номер будинку"
        if (!/^[0-9A-Za-zА-Яа-яІіЇїЄєҐґ\s.,'"\-\/()]+$/.test(address))
            return "Адреса містить недопустимі символи"
        return ""
    }

    function addressErrorMessage() {
        if (!shippingAddressTouched)
            return ""
        return validateShippingAddress(shippingAddressInput.text)
    }

    function isAddressValid() {
        return validateShippingAddress(shippingAddressInput.text).length === 0
    }

    function openLiqPayOverlay() {
        liqPayOverlayLoader.active = true
        if (liqPayOverlayLoader.status === Loader.Ready && liqPayOverlayLoader.item) {
            liqPayOverlayLoader.item.checkoutUrl = root.liqPayCheckoutUrl
            liqPayOverlayLoader.item.open()
        }
    }

    contentWidth: availableWidth
    contentHeight: shell.implicitHeight
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Connections {
        target: cartModel

        function onCheckoutSucceeded(orderId) {
            root.checkoutError = false
            root.checkoutMessage = "Замовлення #" + orderId + " успішно оформлено"
            root.checkoutStep = false
            root.shippingAddressTouched = false
            shippingAddressInput.text = ""
            paymentMethodInput.currentIndex = 0
            if (liqPayOverlayLoader.item && liqPayOverlayLoader.item.visible) {
                liqPayOverlayLoader.item.close()
            }
            root.pendingCheckoutAddress = ""
            root.liqPayCheckoutUrl = ""
            ordersModel.loadOrders()
        }

        function onCheckoutFailed(message) {
            root.checkoutError = true
            root.checkoutMessage = message && message.length > 0 ? message : "Не вдалося оформити замовлення"
        }

        function onLiqPayCheckoutOpened(checkoutUrl) {
            root.checkoutError = false
            root.checkoutMessage = "Книги зарезервовано на 15 хвилин. Завершіть оплату, поки бронь активна."
            root.liqPayCheckoutUrl = checkoutUrl
            root.openLiqPayOverlay()
        }

        function onLiqPayCheckoutFailed(message) {
            root.checkoutError = true
            root.checkoutMessage = message && message.length > 0 ? message : "Не вдалося відкрити LiqPay"
        }
    }

    ColumnLayout {
        id: shell
        width: root.availableWidth
        spacing: 0

        Item { Layout.preferredHeight: Theme.spacingL }

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
                    text: "Кошик доступний після входу"
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 28
                }

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "Увійдіть у профіль, щоб додавати книги в кошик та оформлювати замовлення."
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

        Item {
            visible: appContext && appContext.loggedIn
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
            implicitHeight: stack.implicitHeight

            StackLayout {
                id: stack
                width: parent.width
                currentIndex: root.checkoutStep ? 1 : 0

                Item {
                    implicitHeight: cartColumn.implicitHeight

                    ColumnLayout {
                        id: cartColumn
                        width: parent.width
                        spacing: 0

                        Label {
                            visible: cartModel.count === 0
                            text: "Кошик порожній"
                            color: Theme.textSecondary
                            font.pixelSize: 14
                        }

                        Repeater {
                            model: cartModel

                            Item {
                                Layout.fillWidth: true
                                width: parent ? parent.width : 1000
                                height: 140

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Theme.spacingXL

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingXL

                                        Rectangle {
                                            Layout.preferredWidth: 60
                                            Layout.preferredHeight: 90
                                            color: "#111"
                                            clip: true

                                            Image {
                                                id: coverImage
                                                anchors.fill: parent
                                                source: {
                                                    if (!model.coverImagePath) return ""
                                                    var p = model.coverImagePath
                                                    if (p.indexOf("qrc:/") === 0 || p.indexOf("file:///") === 0 ||
                                                            p.indexOf("http://") === 0 || p.indexOf("https://") === 0) {
                                                        return p
                                                    }
                                                    return "file:///" + p.replace(/\\/g, "/")
                                                }
                                                fillMode: Image.PreserveAspectCrop
                                                smooth: true
                                                visible: status === Image.Ready
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                color: "#555"
                                                opacity: 0.45
                                                visible: coverImage.status === Image.Ready
                                            }

                                            Label {
                                                anchors.centerIn: parent
                                                text: "?"
                                                font.pixelSize: 24
                                                color: Theme.textSecondary
                                                visible: coverImage.status !== Image.Ready
                                            }
                                        }

                                        ColumnLayout {
                                            spacing: 4

                                            Label {
                                                text: model.title
                                                font.family: Theme.fontDisplay.family
                                                font.pixelSize: 20
                                                color: Theme.textPrimary
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                text: model.author
                                                font.family: Theme.fontBody.family
                                                font.pixelSize: 12
                                                color: Theme.textMuted
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    RowLayout {
                                        spacing: Theme.spacingM

                                        Label {
                                            text: "-"
                                            font.family: Theme.fontDisplay.family
                                            font.pixelSize: 20
                                            color: Theme.textPrimary

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: cartModel.decreaseQuantity(model.bookId)
                                            }
                                        }

                                        Label {
                                            text: model.quantity
                                            font.family: Theme.fontDisplay.family
                                            font.pixelSize: 18
                                            color: Theme.textPrimary
                                        }

                                        Label {
                                            text: "+"
                                            font.family: Theme.fontDisplay.family
                                            font.pixelSize: 20
                                            color: Theme.textPrimary

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: cartModel.increaseQuantity(model.bookId)
                                            }
                                        }
                                    }

                                    Label {
                                        text: Number(model.subtotal).toFixed(2) + " UAH"
                                        font.pixelSize: 18
                                        color: Theme.textPrimary
                                    }
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

                        Item { Layout.preferredHeight: Theme.spacingXL }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: Theme.spacingS

                            Label {
                                text: "Усього"
                                font.family: Theme.fontCaption.family
                                font.pixelSize: 12
                                font.capitalization: Font.AllUppercase
                                color: Theme.textMuted
                            }

                            Label {
                                text: Number(cartModel.totalPrice).toFixed(2) + " UAH"
                                font.family: Theme.fontDisplay.family
                                font.pixelSize: 48
                                color: Theme.textPrimary
                            }

                            Rectangle {
                                id: checkoutTriggerButton
                                Layout.preferredWidth: 260
                                Layout.preferredHeight: 50
                                color: checkoutTriggerArea.containsMouse ? Theme.accentWhite : "transparent"
                                border.color: Theme.accentWhite
                                border.width: 1
                                radius: Theme.radiusSharp
                                enabled: cartModel.totalItems > 0
                                opacity: enabled ? 1.0 : 0.4

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: "Оформити замовлення"
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 12
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 2
                                    color: checkoutTriggerArea.containsMouse ? Theme.bgBody : Theme.textPrimary
                                }

                                MouseArea {
                                    id: checkoutTriggerArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: checkoutTriggerButton.enabled
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        root.checkoutMessage = ""
                                        root.checkoutError = false
                                        root.checkoutStep = true
                                    }
                                }
                            }
                        }

                        Item { Layout.preferredHeight: Theme.spacingS }

                        Label {
                            visible: root.checkoutMessage.length > 0
                            Layout.alignment: Qt.AlignRight
                            text: root.checkoutMessage
                            color: root.checkoutError ? Theme.error : Theme.success
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                        }
                    }
                }

                Item {
                    implicitHeight: checkoutCard.implicitHeight

                    Rectangle {
                        id: checkoutCard
                        width: parent.width
                        implicitHeight: checkoutColumn.implicitHeight + Theme.spacingXL * 2
                        radius: Theme.radiusSoft
                        color: Theme.bgCard
                        border.width: 1
                        border.color: Theme.borderLight

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.06) }
                            GradientStop { position: 0.65; color: Qt.rgba(1, 1, 1, 0.025) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.012) }
                        }

                        ColumnLayout {
                            id: checkoutColumn
                            anchors.fill: parent
                            anchors.margins: Theme.spacingXL
                            spacing: Theme.spacingL

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingM

                                Rectangle {
                                    Layout.preferredWidth: 176
                                    Layout.preferredHeight: 38
                                    radius: Theme.radiusPill
                                    color: backArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                    border.width: 1
                                    border.color: Theme.borderLight

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animationFast }
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        text: "← Назад до кошика"
                                        color: Theme.textPrimary
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: backArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.checkoutStep = false
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    Layout.preferredHeight: 32
                                    Layout.preferredWidth: amountLabel.implicitWidth + 28
                                    radius: Theme.radiusRound
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    border.width: 1
                                    border.color: Theme.borderLight

                                    Label {
                                        id: amountLabel
                                        anchors.centerIn: parent
                                        text: "Сума: " + Number(cartModel.totalPrice).toFixed(2) + " UAH"
                                        color: Theme.textPrimary
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 1
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: "Оформлення замовлення"
                                    font.family: Theme.fontDisplay.family
                                    font.pixelSize: root.compactCheckout ? 30 : 36
                                    color: Theme.textPrimary
                                }

                                Label {
                                    text: "Перевірте адресу, оберіть спосіб оплати та підтвердіть замовлення."
                                    color: Theme.textSecondary
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 13
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: root.compactCheckout ? 1 : 2
                                columnSpacing: Theme.spacingXL
                                rowSpacing: Theme.spacingM

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingXS

                                    Label {
                                        text: "Адреса доставки"
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                        font.capitalization: Font.AllUppercase
                                        color: Theme.textMuted
                                        font.letterSpacing: 1
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48
                                        radius: Theme.radiusSoft
                                        color: Qt.rgba(1, 1, 1, 0.02)
                                        border.color: root.addressErrorMessage().length > 0
                                                      ? Theme.error
                                                      : (shippingAddressInput.activeFocus ? Theme.borderHover : Theme.borderLight)
                                        border.width: 1

                                        Behavior on border.color {
                                            ColorAnimation { duration: Theme.animationFast }
                                        }

                                        TextField {
                                            id: shippingAddressInput
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.spacingM
                                            anchors.rightMargin: Theme.spacingM
                                            color: Theme.textPrimary
                                            font.family: Theme.fontBody.family
                                            font.pixelSize: 13
                                            placeholderText: "Вул. Прикладна, 1"
                                            placeholderTextColor: Theme.textMuted
                                            background: Rectangle { color: "transparent" }
                                            onTextChanged: {
                                                if (root.shippingAddressTouched && root.checkoutError && root.checkoutMessage.length > 0) {
                                                    root.checkoutMessage = ""
                                                    root.checkoutError = false
                                                }
                                            }
                                            onEditingFinished: root.shippingAddressTouched = true
                                        }
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        visible: root.addressErrorMessage().length > 0
                                        text: root.addressErrorMessage()
                                        color: Theme.error
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingXS

                                    Label {
                                        text: "Спосіб оплати"
                                        font.family: Theme.fontCaption.family
                                        font.pixelSize: 10
                                        font.capitalization: Font.AllUppercase
                                        color: Theme.textMuted
                                        font.letterSpacing: 1
                                    }

                                    ComboBox {
                                        id: paymentMethodInput
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48
                                        model: ["Готівка", "Картка", "LiqPay Sandbox"]

                                        background: Rectangle {
                                            radius: Theme.radiusSoft
                                            color: Qt.rgba(1, 1, 1, 0.02)
                                            border.width: 1
                                            border.color: paymentMethodInput.activeFocus ? Theme.borderHover : Theme.borderLight

                                            Behavior on border.color {
                                                ColorAnimation { duration: Theme.animationFast }
                                            }
                                        }

                                        contentItem: Label {
                                            leftPadding: Theme.spacingM
                                            rightPadding: Theme.spacingXL
                                            text: paymentMethodInput.displayText
                                            color: Theme.textPrimary
                                            font.family: Theme.fontBody.family
                                            font.pixelSize: 13
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }

                                        indicator: Label {
                                            x: paymentMethodInput.width - width - Theme.spacingM
                                            y: (paymentMethodInput.height - height) / 2
                                            text: "⌄"
                                            color: Theme.textSecondary
                                            font.pixelSize: 16
                                        }

                                        popup: Popup {
                                            y: paymentMethodInput.height + 4
                                            width: paymentMethodInput.width
                                            padding: 0
                                            implicitHeight: contentItem.implicitHeight
                                            background: Rectangle {
                                                radius: Theme.radiusSoft
                                                color: Theme.glassPanel
                                                border.width: 1
                                                border.color: Theme.borderLight
                                            }

                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: paymentMethodInput.popup.visible ? paymentMethodInput.delegateModel : null

                                                delegate: ItemDelegate {
                                                    width: paymentMethodInput.width
                                                    highlighted: paymentMethodInput.highlightedIndex === index
                                                    contentItem: Label {
                                                        text: modelData
                                                        color: highlighted ? Theme.bgBody : Theme.textPrimary
                                                        font.family: Theme.fontBody.family
                                                        font.pixelSize: 13
                                                        elide: Text.ElideRight
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                    background: Rectangle {
                                                        color: highlighted ? Theme.accentWhite : "transparent"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 62
                                radius: Theme.radiusSoft
                                color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.02)
                                border.width: 1
                                border.color: Theme.borderLight

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    spacing: Theme.spacingS

                                    Label {
                                        text: "🔒"
                                        font.pixelSize: 15
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: "Дані замовлення передаються через захищене з'єднання."
                                        color: Theme.textSecondary
                                        font.family: Theme.fontBody.family
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                id: confirmButton
                                Layout.preferredWidth: root.compactCheckout ? 260 : 320
                                Layout.preferredHeight: 54
                                color: confirmArea.containsMouse ? Theme.accentWhite : "transparent"
                                border.color: Theme.accentWhite
                                border.width: 1
                                radius: Theme.radiusRound
                                enabled: cartModel.totalItems > 0 && root.isAddressValid()
                                opacity: enabled ? 1.0 : 0.45

                                Behavior on color {
                                    ColorAnimation { duration: Theme.animationFast }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: paymentMethodInput.currentText === "LiqPay Sandbox"
                                          ? "Перейти до LiqPay"
                                          : "Підтвердити замовлення"
                                    font.family: Theme.fontBody.family
                                    font.pixelSize: 12
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 2
                                    color: confirmArea.containsMouse ? Theme.bgBody : Theme.textPrimary
                                }

                                MouseArea {
                                    id: confirmArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: confirmButton.enabled
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        root.checkoutMessage = ""
                                        root.checkoutError = false
                                        root.shippingAddressTouched = true

                                        var addressError = root.validateShippingAddress(shippingAddressInput.text)
                                        if (addressError.length > 0) {
                                            root.checkoutError = true
                                            root.checkoutMessage = addressError
                                            return
                                        }

                                        if (paymentMethodInput.currentText === "LiqPay Sandbox") {
                                            root.pendingCheckoutAddress = shippingAddressInput.text.trim()
                                            cartModel.startLiqPayCheckout(root.pendingCheckoutAddress)
                                        } else {
                                            cartModel.checkout(shippingAddressInput.text, paymentMethodInput.currentText)
                                        }
                                    }
                                }
                            }

                            Label {
                                visible: root.checkoutMessage.length > 0
                                Layout.fillWidth: true
                                text: root.checkoutMessage
                                color: root.checkoutError ? Theme.error : Theme.success
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Theme.spacingXXL }
    }

    Loader {
        id: liqPayOverlayLoader
        active: true
        asynchronous: true
        source: "qrc:/components/LiqPayCheckoutOverlay.qml"

        onStatusChanged: {
            if (status === Loader.Ready && item && root.liqPayCheckoutUrl.length > 0) {
                item.checkoutUrl = root.liqPayCheckoutUrl
                item.open()
            }
        }
    }

    Connections {
        target: liqPayOverlayLoader.item
        ignoreUnknownSignals: true

        function onVerifyRequested() {
            root.checkoutError = false
            root.checkoutMessage = "Перевіряємо статус платежу..."
            cartModel.verifyPendingLiqPayPayment("")
        }

        function onPaymentReturnDetected(callbackUrl) {
            root.checkoutError = false
            root.checkoutMessage = "Перевіряємо підпис і статус платежу..."
            cartModel.verifyPendingLiqPayPayment(callbackUrl)
        }

        function onPaymentCanceled() {
            cartModel.cancelPendingLiqPayCheckout()
            root.checkoutError = true
            root.checkoutMessage = "Оплату LiqPay скасовано, бронь книг знято"
            root.pendingCheckoutAddress = ""
        }

        function onOverlayClosed() {
            root.liqPayCheckoutUrl = ""
        }
    }
}
