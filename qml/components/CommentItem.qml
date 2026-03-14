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
    property string authorInitial: {
        var name = (root.authorName || "").trim()
        return name.length > 0 ? name.charAt(0).toUpperCase() : "?"
    }

    implicitWidth: parent ? parent.width : 400
    implicitHeight: contentColumn.implicitHeight + Theme.spacingL * 2
    color: Qt.rgba(1, 1, 1, 0.02)
    border.color: Theme.borderLight
    border.width: 1
    radius: Theme.radiusSoft

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Theme.borderLight

                Label {
                    anchors.centerIn: parent
                    text: root.authorInitial
                    color: Theme.textPrimary
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 12
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    text: root.authorName || "Читач"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    text: root.commentDate || ""
                    color: Theme.textMuted
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.8
                    elide: Text.ElideRight
                }
            }

            StarRating {
                rating: root.rating
                starSize: 16
                visible: root.rating > 0
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.commentText
            color: Theme.textPrimary
            wrapMode: Text.Wrap
            font.family: Theme.fontBody.family
            font.pixelSize: 13
            lineHeight: 1.35
            lineHeightMode: Text.ProportionalHeight
        }
    }
}

