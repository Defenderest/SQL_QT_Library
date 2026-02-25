import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"
import ".."

ScrollView {
    id: root

    property int authorId: 0

    contentWidth: availableWidth
    contentHeight: contentColumn.implicitHeight
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    function loadDetails() {
        if (authorId > 0) {
            authorDetailsModel.loadAuthorDetails(authorId)
        }
    }

    onAuthorIdChanged: loadDetails()
    Component.onCompleted: loadDetails()

    ColumnLayout {
        id: contentColumn
        width: root.availableWidth
        spacing: Theme.spacingL

        Rectangle {
            Layout.fillWidth: true
            height: 70
            color: "transparent"

            Button {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingXXL
                anchors.verticalCenter: parent.verticalCenter
                text: "\u2190 \u041d\u0430\u0437\u0430\u0434"
                flat: true
                onClicked: appContext.navigateTo("authors")

                contentItem: Label {
                    text: parent.text
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                    color: Theme.accentWhite
                }
            }
        }

        Rectangle {
            visible: root.authorId <= 0
            Layout.fillWidth: true
            Layout.preferredHeight: 160
            color: "transparent"

            Label {
                anchors.centerIn: parent
                text: "\u041e\u0431\u0435\u0440\u0456\u0442\u044c \u0430\u0432\u0442\u043e\u0440\u0430, \u0449\u043e\u0431 \u043f\u043e\u0431\u0430\u0447\u0438\u0442\u0438 \u0434\u0435\u0442\u0430\u043b\u0456"
                color: Theme.textSecondary
                font.pixelSize: 16
            }
        }

        ColumnLayout {
            visible: root.authorId > 0
            Layout.fillWidth: true
            spacing: Theme.spacingXL

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingXXL
                Layout.rightMargin: Theme.spacingXXL
                spacing: Theme.spacingXXL

                Rectangle {
                    Layout.preferredWidth: Theme.authorPhotoSize
                    Layout.preferredHeight: Theme.authorPhotoSize
                    color: "#111"
                    radius: width / 2
                    clip: true

                    Image {
                        id: authorImage
                        anchors.fill: parent
                        source: {
                            var p = authorDetailsModel.imagePath
                            if (!p)
                                return ""
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

                    Label {
                        anchors.centerIn: parent
                        text: "?"
                        font.pixelSize: 64
                        color: Theme.textSecondary
                        visible: authorImage.status !== Image.Ready
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    Label {
                        Layout.fillWidth: true
                        text: authorDetailsModel.fullName
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 42
                        color: Theme.textPrimary
                        wrapMode: Text.Wrap
                    }

                    Label {
                        text: (authorDetailsModel.nationality || "").toUpperCase()
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 12
                        font.letterSpacing: 1
                        color: Theme.textMuted
                    }

                    Label {
                        text: authorDetailsModel.birthDate.length > 0
                              ? "\u0414\u0430\u0442\u0430 \u043d\u0430\u0440\u043e\u0434\u0436\u0435\u043d\u043d\u044f: " + authorDetailsModel.birthDate
                              : "\u0414\u0430\u0442\u0430 \u043d\u0430\u0440\u043e\u0434\u0436\u0435\u043d\u043d\u044f: -"
                        color: Theme.textSecondary
                        font.pixelSize: 14
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingXXL
                Layout.rightMargin: Theme.spacingXXL
                spacing: Theme.spacingS

                Label {
                    text: "\u0411\u0456\u043e\u0433\u0440\u0430\u0444\u0456\u044f"
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                    color: Theme.textPrimary
                }

                Label {
                    Layout.fillWidth: true
                    text: authorDetailsModel.biography || "\u0411\u0456\u043e\u0433\u0440\u0430\u0444\u0456\u044f \u0432\u0456\u0434\u0441\u0443\u0442\u043d\u044f"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                    color: Theme.textSecondary
                    wrapMode: Text.Wrap
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingXXL
                Layout.rightMargin: Theme.spacingXXL
                spacing: Theme.spacingM

                Label {
                    text: "\u041a\u043d\u0438\u0433\u0438 \u0430\u0432\u0442\u043e\u0440\u0430"
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                    color: Theme.textPrimary
                }

                Label {
                    visible: authorDetailsModel.books.length === 0
                    text: "\u041a\u043d\u0438\u0433\u0438 \u0432\u0456\u0434\u0441\u0443\u0442\u043d\u0456"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 40
                    flow: Flow.LeftToRight

                    Repeater {
                        model: authorDetailsModel.books

                        BookCard {
                            bookId: modelData.bookId
                            title: modelData.title
                            authors: modelData.authors
                            price: modelData.price
                            coverImagePath: modelData.coverImagePath
                            stockQuantity: modelData.stockQuantity
                            genre: modelData.genre

                            onClicked: function(id) {
                                appContext.navigateToBookDetails(id)
                            }

                            onAddToCart: function(id) {
                                if (!(appContext && appContext.loggedIn)) {
                                    appContext.navigateTo("profile")
                                    return
                                }
                                cartModel.addItem(id)
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Theme.spacingXXL }
        }
    }
}
