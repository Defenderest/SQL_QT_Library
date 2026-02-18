import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Rectangle {
    id: root

    property int authorId: 0
    property string firstName: ""
    property string lastName: ""
    property string nationality: ""
    property string imagePath: ""

    signal clicked(int authorId)

    width: 280
    height: 280
    color: Qt.rgba(1, 1, 1, 0.01)
    border.color: mouseArea.containsMouse ? Theme.borderHover : Theme.borderLight
    border.width: 1
    radius: Theme.radiusSharp

    Behavior on border.color {
        ColorAnimation { duration: Theme.animationFast }
    }

    transform: Translate {
        y: mouseArea.containsMouse ? -5 : 0
        Behavior on y {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        focus: false
        preventStealing: true

        onClicked: root.clicked(root.authorId)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            color: "#111"
            radius: width / 2
            clip: true

            Image {
                id: authorImage
                anchors.fill: parent
                source: {
                    if (!root.imagePath) return ""
                    var p = root.imagePath
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
                visible: authorImage.status === Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                color: "#111"
                visible: authorImage.status !== Image.Ready

                Label {
                    anchors.centerIn: parent
                    text: "?"
                    font.pixelSize: 36
                    color: Theme.textSecondary
                }
            }
        }

        Item { Layout.preferredHeight: 20 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Label {
                Layout.fillWidth: true
                text: root.firstName + " " + root.lastName
                font.family: Theme.fontDisplay.family
                font.pixelSize: 20
                color: Theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                text: (root.nationality || "").toUpperCase() + (root.nationality ? " \u2022 AUTHOR" : "AUTHOR")
                font.family: Theme.fontCaption.family
                font.pixelSize: 12
                color: Theme.textMuted
                font.letterSpacing: 1
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }
}
