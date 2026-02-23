import QtQuick 2.15
import QtQuick.Controls 2.15
import ".."

Rectangle {
    id: root

    property int count: 0
    property int badgeSize: 20

    width: badgeSize
    height: badgeSize
    radius: badgeSize / 2
    color: Theme.accentWhite
    visible: count > 0

    Behavior on scale {
        NumberAnimation { duration: Theme.animationFast }
    }

    scale: count > 0 ? 1.0 : 0.0

    Label {
        anchors.centerIn: parent
        text: root.count.toString()
        font.bold: true
        color: Theme.bgBody
    }
}
