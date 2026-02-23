pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebEngine 1.15

Popup {
    id: root

    property string checkoutUrl: ""

    signal paymentSucceeded()
    signal paymentCanceled()
    signal overlayClosed()

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

    WebEngineProfile {
        id: liqPayProfile
        offTheRecord: true
        httpCacheType: WebEngineProfile.MemoryHttpCache
        persistentCookiesPolicy: WebEngineProfile.NoPersistentCookies
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

                Button {
                    id: successButton
                    text: "Оплату виконано"
                    onClicked: {
                        root.paymentSucceeded()
                        root.close()
                    }

                    background: Rectangle {
                        radius: Theme.radiusRound
                        border.width: 1
                        border.color: Theme.accentWhite
                        color: successButton.hovered ? Theme.accentWhite : "transparent"
                    }

                    contentItem: Label {
                        text: successButton.text
                        color: successButton.hovered ? Theme.bgBody : Theme.textPrimary
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
            active: root.visible
            asynchronous: true
            sourceComponent: webComponent
        }
    }

    Component {
        id: webComponent

        WebEngineView {
            id: liqPayWeb
            url: root.checkoutUrl
            profile: liqPayProfile
            focus: true

            settings.javascriptEnabled: true
            settings.pluginsEnabled: false
            settings.fullScreenSupportEnabled: true
            settings.autoLoadImages: true

            onLoadingChanged: function(loadRequest) {
                var current = liqPayWeb.url.toString()
                if (current.indexOf("liqpay.local/result") !== -1) {
                    var lower = current.toLowerCase()
                    if (lower.indexOf("status=success") !== -1 ||
                        lower.indexOf("status=sandbox") !== -1 ||
                        lower.indexOf("status=processing") !== -1 ||
                        lower.indexOf("status=wait_accept") !== -1) {
                        root.paymentSucceeded()
                    } else {
                        root.paymentCanceled()
                    }
                    root.close()
                }
            }
        }
    }
}
