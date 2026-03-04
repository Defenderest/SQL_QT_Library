pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebEngine 1.15

Popup {
    id: root

    property string checkoutUrl: ""
    property bool slowLoading: false
    property bool resultCallbackHandled: false

    signal verifyRequested()
    signal paymentReturnDetected(string callbackUrl)
    signal paymentCanceled()
    signal overlayClosed()

    function currentWebView() {
        return (webLoader && webLoader.item) ? webLoader.item : null
    }

    function decodeQueryParam(urlValue, name) {
        var escapedName = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
        var regex = new RegExp("[?&]" + escapedName + "=([^&]+)")
        var match = regex.exec(urlValue || "")
        return match && match.length > 1 ? decodeURIComponent(match[1]) : ""
    }

    function htmlEscape(value) {
        return (value || "")
                .replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/\"/g, "&quot;")
                .replace(/'/g, "&#39;")
    }

    function loadCheckoutPage() {
        if (!root.checkoutUrl || root.checkoutUrl.length === 0)
            return

        var webView = currentWebView()
        if (!webView)
            return

        root.slowLoading = false
        root.resultCallbackHandled = false

        var dataParam = decodeQueryParam(root.checkoutUrl, "data")
        var signatureParam = decodeQueryParam(root.checkoutUrl, "signature")

        if (dataParam.length > 0 && signatureParam.length > 0) {
            var html = "<!doctype html><html><head><meta charset='utf-8'></head><body style='background:#030303;margin:0;'>"
                     + "<form id='liqpay' method='POST' action='https://www.liqpay.ua/api/3/checkout'>"
                     + "<input type='hidden' name='data' value='" + htmlEscape(dataParam) + "'>"
                     + "<input type='hidden' name='signature' value='" + htmlEscape(signatureParam) + "'>"
                     + "</form><script>document.getElementById('liqpay').submit();</script></body></html>"
            webView.loadHtml(html, "https://www.liqpay.ua/")
        } else {
            webView.url = root.checkoutUrl
        }

        slowLoadTimer.restart()
    }

    parent: Overlay.overlay
    x: 0
    y: 0
    width: parent ? parent.width : 1200
    height: parent ? parent.height : 800
    padding: 0
    modal: true
    focus: true
    closePolicy: Popup.NoAutoClose

    background: Rectangle {
        color: Theme.bgBody
    }

    onClosed: overlayClosed()
    onOpened: loadCheckoutPage()
    onCheckoutUrlChanged: {
        if (root.visible)
            loadCheckoutPage()
    }

    WebEngineProfile {
        id: liqPayProfile
        offTheRecord: false
        storageName: "liqpay_checkout"
        httpCacheType: WebEngineProfile.DiskHttpCache
        persistentCookiesPolicy: WebEngineProfile.AllowPersistentCookies
    }

    Timer {
        id: slowLoadTimer
        interval: 10000
        repeat: false
        onTriggered: {
            var webView = root.currentWebView()
            if (webView && (webView.loading || webView.loadProgress < 100))
                root.slowLoading = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 62
            color: Theme.glassPanel
            border.width: 1
            border.color: Theme.borderLight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingL
                anchors.rightMargin: Theme.spacingL
                spacing: Theme.spacingM

                Label {
                    text: "LiqPay Sandbox"
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                }

                Label {
                    text: "Тестовий режим"
                    color: Theme.textMuted
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.1
                }

                Item { Layout.fillWidth: true }

                Label {
                    visible: root.slowLoading
                    text: "Завантаження довше звичайного"
                    color: Theme.warning
                    font.family: Theme.fontBody.family
                    font.pixelSize: 11
                }

                Button {
                    id: verifyButton
                    text: "Перевірити оплату"
                    onClicked: root.verifyRequested()

                    background: Rectangle {
                        radius: Theme.radiusRound
                        border.width: 1
                        border.color: Theme.accentWhite
                        color: verifyButton.hovered ? Theme.accentWhite : "transparent"
                    }

                    contentItem: Label {
                        text: verifyButton.text
                        color: verifyButton.hovered ? Theme.bgBody : Theme.textPrimary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 11
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    id: cancelButton
                    text: "Скасувати"
                    onClicked: {
                        root.paymentCanceled()
                        root.close()
                    }

                    background: Rectangle {
                        radius: Theme.radiusRound
                        border.width: 1
                        border.color: Theme.borderLight
                        color: cancelButton.hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    }

                    contentItem: Label {
                        text: cancelButton.text
                        color: Theme.textSecondary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 11
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Loader {
            id: webLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: true
            asynchronous: false
            sourceComponent: webComponent

            onStatusChanged: {
                if (status === Loader.Ready && root.visible && root.checkoutUrl.length > 0) {
                    root.loadCheckoutPage()
                }
            }
        }
    }

    Component {
        id: webComponent

        WebEngineView {
            id: liqPayWeb
            url: "about:blank"
            profile: liqPayProfile
            focus: true

            settings.javascriptEnabled: true
            settings.pluginsEnabled: false
            settings.fullScreenSupportEnabled: true
            settings.autoLoadImages: true
            settings.webGLEnabled: false
            settings.accelerated2dCanvasEnabled: false

            Rectangle {
                anchors.fill: parent
                visible: liqPayWeb.loading
                color: Theme.bgBody
                z: 2

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM

                    BusyIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        running: liqPayWeb.loading
                    }

                    Label {
                        text: "Завантаження сторінки LiqPay..."
                        color: Theme.textSecondary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                    }
                }
            }

            onLoadingChanged: function(loadRequest) {
                var status = loadRequest ? loadRequest.status : -1

                if (status === 2) { // LoadSucceededStatus
                    root.slowLoading = false
                    slowLoadTimer.stop()
                }

                if (status === 3) { // LoadFailedStatus
                    root.slowLoading = true
                    slowLoadTimer.stop()
                }

                var current = liqPayWeb.url.toString()
                if (current.indexOf("liqpay.local/result") !== -1) {
                    if (!root.resultCallbackHandled) {
                        root.resultCallbackHandled = true
                        root.paymentReturnDetected(current)
                    }
                    slowLoadTimer.stop()
                    root.slowLoading = false
                }
            }

            onRenderProcessTerminated: function(terminationStatus, exitCode) {
                console.warn("LiqPay WebEngine render process terminated", terminationStatus, exitCode)
            }
        }
    }
}
