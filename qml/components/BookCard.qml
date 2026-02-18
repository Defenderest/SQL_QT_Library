import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Rectangle {
    id: root

    property int bookId: 0
    property string title: ""
    property string authors: ""
    property double price: 0.0
    property string coverImagePath: ""
    property int stockQuantity: 0
    property string genre: ""

    // Для spotlight эффекта
    property real mouseX: 0
    property real mouseY: 0

    signal clicked(int bookId)
    signal addToCart(int bookId)

    // Размеры карточки как в макете (высота увеличена на 20px)
    width: 280
    height: 560

    color: Qt.rgba(1, 1, 1, 0.01)
    border.color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.08)
    border.width: 1
    radius: Theme.radiusSharp

    // Spotlight glow layer
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: parent.radius
        clip: true

        Rectangle {
            width: 600
            height: 600
            x: root.mouseX - width/2
            y: root.mouseY - height/2
            radius: width/2
            color: Qt.rgba(1, 1, 1, 0.06)
            opacity: mouseArea.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }
        }
    }

    // Эффекты при наведении
    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }

    // Эффект подъема - используем transform вместо y чтобы не влиять на layout
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
        // Отключаем фокус чтобы не было авто-скролла
        focus: false
        preventStealing: true

        onPositionChanged: {
            root.mouseX = mouse.x
            root.mouseY = mouse.y
        }

        onClicked: root.clicked(root.bookId)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0

        // Обложка книги - aspect ratio 2/3 как в макете
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: width * 3 / 2  // 2:3 ratio
            color: "#111"
            radius: Theme.radiusSharp
            clip: true

            // Grayscale overlay по умолчанию (как в макете)
            Rectangle {
                anchors.fill: parent
                color: "#444"
                opacity: mouseArea.containsMouse ? 0 : 0.5
                visible: coverImage.status === Image.Ready
                z: 1

                Behavior on opacity {
                    NumberAnimation { duration: 600 }
                }
            }

            Image {
                id: coverImage
                anchors.fill: parent
                source: root.coverImagePath ? "file:///" + root.coverImagePath.replace(/\\/g, "/") : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true

                onStatusChanged: {
                    if (status === Image.Error) {
                        console.log("Image error:", source)
                    }
                }
            }

            // Scale эффект при наведении
            scale: mouseArea.containsMouse ? 1.05 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 1500; easing.type: Easing.OutCubic }
            }

            // Плейсхолдер
            Rectangle {
                anchors.fill: parent
                color: "#111"
                visible: coverImage.status !== Image.Ready

                Label {
                    anchors.centerIn: parent
                    text: "📖"
                    font.pixelSize: 32
                    color: "#888"
                }
            }
        }

        // Отступ между картинкой и текстом (25px как в макете)
        Item { Layout.preferredHeight: 25 }

        // Инфо
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            // Название - Playfair Display 20px
            Label {
                Layout.fillWidth: true
                text: root.title
                font.family: Theme.fontDisplay.family
                font.pixelSize: 20
                color: "#ffffff"
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Авторы - 12px, #666, uppercase, letter-spacing: 1px
            Label {
                Layout.fillWidth: true
                text: (root.authors || "Невідомий автор").toUpperCase()
                font.family: Theme.fontCaption.family
                font.pixelSize: 12
                font.letterSpacing: 1
                color: "#666666"
                elide: Text.ElideRight
            }

            // Цена - как в макете: UAH 350.00, margin-top: 15px
            Label {
                Layout.fillWidth: true
                Layout.topMargin: 15
                text: "UAH " + root.price.toFixed(2)
                font.family: Theme.fontDisplay.family
                font.pixelSize: 14
                font.weight: Font.Medium
                color: "#ffffff"
            }
        }

        Item { Layout.preferredHeight: 18 }

        Rectangle {
            id: addToCartButton
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            color: addToCartArea.containsMouse && root.stockQuantity > 0 ? Theme.accentWhite : "transparent"
            border.color: root.stockQuantity > 0 ? Theme.accentWhite : Theme.borderLight
            border.width: 1
            radius: Theme.radiusSharp
            opacity: root.stockQuantity > 0 ? 1.0 : 0.55

            Behavior on color {
                ColorAnimation { duration: Theme.animationFast }
            }

            Label {
                anchors.centerIn: parent
                text: root.stockQuantity > 0
                      ? "\u0414\u043e\u0434\u0430\u0442\u0438 \u0432 \u043a\u043e\u0448\u0438\u043a"
                      : "\u041d\u0435\u043c\u0430\u0454 \u0432 \u043d\u0430\u044f\u0432\u043d\u043e\u0441\u0442\u0456"
                font.family: Theme.fontBody.family
                font.pixelSize: 11
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                color: addToCartArea.containsMouse && root.stockQuantity > 0 ? Theme.bgBody : Theme.textPrimary
            }

            MouseArea {
                id: addToCartArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.stockQuantity > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.addToCart(root.bookId)
            }
        }

        Item { Layout.preferredHeight: 8 }
    }
}
