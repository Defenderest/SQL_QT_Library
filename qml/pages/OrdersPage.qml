import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

ScrollView {
    id: root

    contentWidth: availableWidth
    contentHeight: contentColumn.implicitHeight
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Component.onCompleted: {
        console.log("OrdersPage loaded, loading orders...")
        ordersModel.loadOrders()
    }

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
                        onClicked: appContext.showOrderDetails(model.orderId)
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
}
