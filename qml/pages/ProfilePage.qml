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

    property string saveMessage: ""

    Component.onCompleted: {
        console.log("ProfilePage loaded, loading profile...")
        profileModel.loadProfile()
    }

    ColumnLayout {
        id: contentColumn
        width: root.availableWidth
        spacing: 0

        Item { Layout.preferredHeight: 40 }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
            Layout.bottomMargin: 40
            spacing: 30

            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                radius: 40
                color: "#222"

                Label {
                    anchors.centerIn: parent
                    text: ""
                }
            }

            ColumnLayout {
                spacing: 4

                Label {
                    text: (profileModel.firstName + " " + profileModel.lastName).trim()
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 32
                    color: Theme.textPrimary
                }

                Label {
                    text: profileModel.loyaltyProgram ? "ПРЕМІУМ УЧАСНИК" : "УЧАСНИК"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 12
                    font.letterSpacing: 1
                    color: Theme.textMuted
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
            Layout.maximumWidth: 800
            columns: 2
            columnSpacing: 40
            rowSpacing: 24

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Ім'я"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                TextField {
                    id: firstNameField
                    Layout.fillWidth: true
                    text: profileModel.firstName
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: firstNameField.activeFocus ? Theme.accentWhite : Theme.borderLight
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Прізвище"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                TextField {
                    id: lastNameField
                    Layout.fillWidth: true
                    text: profileModel.lastName
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: lastNameField.activeFocus ? Theme.accentWhite : Theme.borderLight
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Електронна пошта"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                TextField {
                    id: emailField
                    Layout.fillWidth: true
                    text: profileModel.email
                    readOnly: true
                    color: Theme.textSecondary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "transparent"
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Телефон"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                TextField {
                    id: phoneField
                    Layout.fillWidth: true
                    text: profileModel.phone
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: phoneField.activeFocus ? Theme.accentWhite : Theme.borderLight
                        }
                    }
                }
            }
        }

        Rectangle {
            id: saveButton
            Layout.topMargin: 50
            Layout.leftMargin: Theme.spacingXXL
            width: 190
            height: 50
            color: saveArea.containsMouse ? Theme.accentWhite : "transparent"
            border.color: Theme.accentWhite
            border.width: 1

            Behavior on color {
                ColorAnimation { duration: Theme.animationFast }
            }

            Label {
                anchors.centerIn: parent
                text: "Зберегти зміни"
                font.family: Theme.fontBody.family
                font.pixelSize: 12
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 2
                color: saveArea.containsMouse ? Theme.bgBody : Theme.textPrimary
            }

            MouseArea {
                id: saveArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var ok = profileModel.updateProfile(
                                firstNameField.text,
                                lastNameField.text,
                                phoneField.text,
                                profileModel.address)
                    saveMessage = ok ? "Збережено" : "Помилка збереження"
                }
            }
        }

        Label {
            Layout.topMargin: 12
            Layout.leftMargin: Theme.spacingXXL
            text: root.saveMessage
            visible: text.length > 0
            color: Theme.textSecondary
            font.pixelSize: 12
        }

        Item { Layout.preferredHeight: Theme.spacingXXL }
    }
}
