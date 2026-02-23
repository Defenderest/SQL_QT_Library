import QtQuick 2.15
import QtQuick.Controls 2.15
import ".."

Row {
    id: root

    property int rating: 0
    property int maximumRating: 5
    property bool interactive: false
    property int starSize: 20

    signal ratingSelected(int newRating)

    spacing: 2

    Repeater {
        model: root.maximumRating

        Text {
            text: index < root.rating ? "\u2605" : "\u2606"
            font.pixelSize: root.starSize
            color: index < root.rating ? Theme.accentWhite : Theme.textSecondary
            opacity: root.interactive ? (mouseArea.containsMouse ? 1.0 : 0.8) : 1.0

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: root.interactive
                hoverEnabled: root.interactive
                cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                    if (root.interactive) {
                        root.ratingSelected(index + 1)
                    }
                }
            }

            Behavior on color {
                ColorAnimation { duration: Theme.animationFast }
            }
        }
    }
}

