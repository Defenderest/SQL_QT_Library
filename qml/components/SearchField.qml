import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Rectangle {
    id: root

    signal search(string text)

    height: 40
    color: Theme.glassPanel
    border.color: searchField.activeFocus ? Theme.accentWhite : Theme.borderLight
    border.width: 1
    radius: Theme.radiusSoft

    Behavior on border.color {
        ColorAnimation { duration: Theme.animationFast }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingS

        Text {
            text: "🔍"
            font.pixelSize: 16
            color: Theme.textSecondary
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: "Пошук книг та авторів..."
            placeholderTextColor: Theme.textSecondary
            color: Theme.textPrimary
            background: null

            onAccepted: root.search(text)

            Keys.onReturnPressed: root.search(text)
            Keys.onEnterPressed: root.search(text)
        }
    }
}
