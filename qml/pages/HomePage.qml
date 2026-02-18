import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"
import ".."

ScrollView {
    id: root

    property var dbManager: appContext ? appContext.dbManager : null

    contentWidth: availableWidth
    contentHeight: contentColumn.height
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
        id: contentColumn
        width: parent.width
        spacing: 0

        // ========== HERO SECTION ==========
        Rectangle {
            Layout.fillWidth: true
            // Адаптивная высота Hero - минимум 250, максимум 400
            Layout.preferredHeight: Math.max(250, Math.min(400, parent.width * 0.35))
            color: "#111"
            clip: true

            // Фоновое изображение (затемнённое)
            Image {
                id: heroBg
                anchors.fill: parent
                source: "qrc:/images/banner2.jpg"
                fillMode: Image.PreserveAspectCrop
                smooth: true
                opacity: 0.4
            }

            // Дополнительное затемнение
            Rectangle {
                anchors.fill: parent
                color: "#030303"
                opacity: 0.6
            }

            // Градиентная маска снизу
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#030303" }
                    GradientStop { position: 1.0; color: "#030303" }
                }
            }

            // Граница снизу
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.borderLight
            }

            // Контент Hero
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                // Адаптивные отступы
                anchors.margins: Theme.spacingXXL
                spacing: Theme.spacingM

                // Заголовок - адаптивный размер шрифта
                Label {
                    text: "Естетика"
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: Math.min(64, Math.max(32, root.width / 20))
                    color: Theme.textPrimary
                }
                Label {
                    text: "Тиші."
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: Math.min(64, Math.max(32, root.width / 20))
                    color: Theme.textPrimary
                }

                // Описание
                Label {
                    Layout.maximumWidth: 400
                    text: "Лімітована колекція архітектурних та філософських видань."
                    font.family: Theme.fontBody.family
                    font.weight: Font.Light
                    font.pixelSize: 14
                    color: Qt.rgba(1, 1, 1, 0.8)
                    wrapMode: Text.Wrap
                }

                // Кнопка
                Button {
                    id: heroBtn
                    Layout.topMargin: Theme.spacingM

                    contentItem: Label {
                        text: "Відкрити Каталог"
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                        font.letterSpacing: 2
                        font.capitalization: Font.AllUppercase
                        color: heroBtn.hovered ? Theme.bgBody : Theme.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        implicitWidth: 200
                        implicitHeight: 45
                        color: heroBtn.hovered ? Theme.accentWhite : "transparent"
                        border.color: Theme.accentWhite
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: Theme.animationFast }
                        }
                    }

                    onClicked: {
                        if (appContext) appContext.navigateTo("books")
                    }
                }
            }
        }

        // ========== НОВИНКИ КОЛЕКЦІЇ ==========
        ColumnLayout {
            Layout.fillWidth: true
            // Адаптивные отступы - меньше на маленьких экранах
            Layout.margins: Theme.spacingXXL
            Layout.topMargin: Theme.spacingXL
            spacing: Theme.spacingL

            // Подзаголовок
            Label {
                text: "Новинки Колекції"
                font.family: Theme.fontDisplay.family
                font.pixelSize: 24
                font.weight: Font.Normal
                color: Theme.textPrimary
            }

            // Сетка карточек - адаптивная Flow layout
            Flow {
                id: booksFlow
                Layout.fillWidth: true
                spacing: 40
                flow: Flow.LeftToRight

                // Показываем placeholder если модель пустая
                Rectangle {
                    visible: newArrivalsModel.count === 0
                    width: visible ? Math.min(840, booksFlow.width - 40) : 0
                    height: visible ? 200 : 0
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 16

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Завантаження..."
                            font.family: Theme.fontBody.family
                            font.pixelSize: 18
                            color: Theme.textSecondary
                        }

                        // Прогресс индикатор
                        Rectangle {
                            id: homeProgressBar
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 200
                            height: 2
                            color: Theme.borderLight

                            Rectangle {
                                id: homeProgressIndicator
                                width: homeProgressBar.width * 0.6
                                height: homeProgressBar.height
                                color: Theme.textPrimary

                                SequentialAnimation on x {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0; to: homeProgressBar.width - homeProgressIndicator.width; duration: 1000 }
                                    NumberAnimation { from: homeProgressBar.width - homeProgressIndicator.width; to: 0; duration: 1000 }
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: newArrivalsModel
                    delegate: BookCardHome {
                        // Фиксированный размер как в макете (высота увеличена на 20px)
                        width: 280
                        height: 500
                        bookId: model.bookId
                        title: model.title
                        authors: model.authors
                        coverImagePath: model.coverImagePath

                        onClicked: function(bookId) {
                            appContext.navigateToBookDetails(bookId)
                        }
                    }
                }
            }
        }

        // Отступ снизу
        Item { Layout.preferredHeight: Theme.spacingXXL }
    }
}
