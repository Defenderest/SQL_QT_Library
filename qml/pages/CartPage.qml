import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

ScrollView {
    id: root

    contentWidth: availableWidth
    contentHeight: contentColumn.height
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
        id: contentColumn
        width: root.availableWidth
        spacing: 0

        Item { Layout.preferredHeight: 20 }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
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
                    implicitHeight: 150

                    RowLayout {
                        anchors.fill: parent
                        anchors.topMargin: 30
                        anchors.bottomMargin: 30
                        spacing: 30

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 30

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
                                spacing: 5

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
                            spacing: 15

                            Label {
                                text: "-"
                                font.family: Theme.fontDisplay.family
                                font.pixelSize: 18
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
                                font.pixelSize: 18
                                color: Theme.textPrimary

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cartModel.increaseQuantity(model.bookId)
                                }
                            }
                        }

                        Label {
                            text: Number(model.subtotal).toFixed(2) + " ₴"
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

            Item { Layout.preferredHeight: 50 }

            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Label {
                    text: "Усього"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 12
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }

                Label {
                    text: Number(cartModel.totalPrice).toFixed(2) + " ₴"
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 48
                    color: Theme.textPrimary
                }

                Rectangle {
                    id: checkoutButton
                    width: 180
                    height: 50
                    color: checkoutArea.containsMouse ? Theme.accentWhite : "transparent"
                    border.color: Theme.accentWhite
                    border.width: 1
                    enabled: cartModel.totalItems > 0
                    opacity: enabled ? 1.0 : 0.4

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Checkout"
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 2
                        color: checkoutArea.containsMouse ? Theme.bgBody : Theme.textPrimary
                    }

                    MouseArea {
                        id: checkoutArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: checkoutButton.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appContext.checkout()
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Theme.spacingXXL }
    }
}
