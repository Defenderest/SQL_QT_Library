import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Rectangle {
    id: root

    property string authorName: ""
    property string commentDate: ""
    property int rating: 0
    property string commentText: ""

    width: parent ? parent.width : 400
    height: contentColumn.implicitHeight + Theme.spacingL * 2
    color: Theme.glassPanel
    border.color: Theme.borderLight
    border.width: 1
    radius: Theme.radiusSoft

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: root.authorName
                font.bold: true
                color: Theme.accentWhite
            }

            Label {
                text: "\u2022"
                color: Theme.textSecondary
            }

            Label {
                text: root.commentDate
                color: Theme.textSecondary
            }
        }

        StarRating {
            rating: root.rating
            starSize: 16
            visible: root.rating > 0
        }

        Label {
            Layout.fillWidth: true
            text: root.commentText
            color: Theme.textPrimary
            wrapMode: Text.Wrap
        }
    }
}

