import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Rectangle {
    id: root

    property int bookId: 0
    property string title: ""
    property string authors: ""
    property string coverImagePath: ""

    // Для spotlight эффекта
    property real mouseX: 0
    property real mouseY: 0

    signal clicked(int bookId)

    width: 280
    height: 500
    color: "transparent"
    border.color: Theme.borderLight
    border.width: 1
    radius: Theme.radiusSharp

    // Spotlight glow layer
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: parent.radius
        clip: true

        Rectangle {
            width: 400
            height: 400
            x: root.mouseX - width/2
            y: root.mouseY - height/2
            radius: width/2
            color: Theme.spotlightColor
            opacity: mouseArea.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }
    }

    Behavior on border.color {
        ColorAnimation { duration: Theme.animationFast }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        focus: false
        preventStealing: true

        onPositionChanged: {
            root.mouseX = mouse.x
            root.mouseY = mouse.y
        }

        onClicked: root.clicked(root.bookId)

        onEntered: root.border.color = Qt.rgba(1, 1, 1, 0.2)
        onExited: root.border.color = Theme.borderLight
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Обложка книги (aspect-ratio 2/3)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: width * 1.5  // 2:3 ratio
            color: "#111"
            radius: Theme.radiusSharp
            clip: true

            Image {
                id: coverImage
                anchors.fill: parent
                source: root.coverImagePath ? "file:///" + root.coverImagePath.replace(/\\/g, "/") : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true

                onStatusChanged: {
                    if (status === Image.Error) {
                        console.log("Image error:", root.coverImagePath)
                    }
                }
            }

            // Grayscale overlay
            Rectangle {
                anchors.fill: parent
                color: "#888"
                opacity: mouseArea.containsMouse ? 0 : 0.4
                visible: coverImage.status === Image.Ready

                Behavior on opacity {
                    NumberAnimation { duration: 400 }
                }
            }

            // Плейсхолдер
            Rectangle {
                anchors.fill: parent
                color: "#111"
                visible: coverImage.status !== Image.Ready

                Label {
                    anchors.centerIn: parent
                    text: coverImage.status === Image.Error ? "❌" : "📖"
                    font.pixelSize: 48
                    color: Theme.textSecondary
                }
            }

            // Масштабирование при наведении - используем transform
            transform: Scale {
                id: cardScale
                xScale: mouseArea.containsMouse ? 1.02 : 1.0
                yScale: mouseArea.containsMouse ? 1.02 : 1.0
                origin.x: width / 2
                origin.y: height / 2

                Behavior on xScale {
                    NumberAnimation { duration: 1500; easing.type: Easing.OutCubic }
                }
                Behavior on yScale {
                    NumberAnimation { duration: 1500; easing.type: Easing.OutCubic }
                }
            }
        }

        // Мета-информация
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Название - Playfair Display 20px
            Label {
                Layout.fillWidth: true
                text: root.title
                font.family: Theme.fontDisplay.family
                font.pixelSize: 20
                color: Theme.textPrimary
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Авторы - маленький CAPS
            Label {
                Layout.fillWidth: true
                text: (root.authors || "Невідомий автор").toUpperCase()
                font.family: Theme.fontCaption.family
                font.pixelSize: 12
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }
    }
}
