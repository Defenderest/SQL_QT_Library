import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Rectangle {
    id: root

    property bool panelVisible: false

    color: Theme.glassPanel
    border.color: Theme.borderLight
    border.width: 1

    // Левая граница потолще
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: Theme.borderLight
    }

    x: panelVisible ? parent.width - width : parent.width

    Behavior on x {
        NumberAnimation { duration: Theme.animationSmooth; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Заголовок
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Фільтри"
                color: Theme.textPrimary
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "✕"
                flat: true
                onClicked: root.panelVisible = false
            }
        }

        // Разделитель
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderLight
        }

        // Жанры
        Label {
            text: "Жанри"
            font.bold: true
            color: Theme.textPrimary
        }

        // TODO: Список жанров с чекбоксами

        // Языки
        Label {
            text: "Мова"
            font.bold: true
            color: Theme.textPrimary
        }

        // TODO: Список языков

        // Цена
        Label {
            text: "Ціна"
            font.bold: true
            color: Theme.textPrimary
        }

        // TODO: Слайдер цены

        // В наличии
        CheckBox {
            text: "Тільки в наявності"
            contentItem: Label {
                text: parent.text
                color: Theme.textPrimary
                leftPadding: parent.indicator.width + parent.spacing
            }
        }

        Item { Layout.fillHeight: true }

        // Кнопки
        RowLayout {
            Layout.fillWidth: true

            Button {
                Layout.fillWidth: true
                text: "Скинути"
                flat: true
                onClicked: {
                    // TODO: сбросить фильтры
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Застосувати"

                background: Rectangle {
                    color: parent.pressed ? Theme.textSecondary : Theme.accentWhite
                    radius: Theme.radiusSoft
                }

                contentItem: Label {
                    text: parent.text
                    color: Theme.bgBody
                    horizontalAlignment: Text.AlignHCenter
                }

                onClicked: {
                    // TODO: применить фильтры
                    root.panelVisible = false
                }
            }
        }
    }
}
