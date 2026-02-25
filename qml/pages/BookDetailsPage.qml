import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"
import ".."

ScrollView {
    id: root

    property int bookId: 0
    property int selectedRating: 5
    property string feedbackMessage: ""
    property bool feedbackError: false

    contentWidth: availableWidth
    contentHeight: contentColumn.implicitHeight
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    function loadDetails() {
        if (root.bookId > 0) {
            bookDetailsModel.loadBookDetails(root.bookId)
            feedbackMessage = ""
        }
    }

    onBookIdChanged: loadDetails()
    Component.onCompleted: loadDetails()

    Connections {
        target: bookDetailsModel

        function onErrorOccurred(message) {
            root.feedbackError = true
            root.feedbackMessage = message
        }
    }

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
                text: "\u2190 Назад"
                flat: true
                onClicked: appContext.navigateTo("books")

                contentItem: Label {
                    text: parent.text
                    font.family: Theme.fontBody.family
                    font.pixelSize: 14
                    color: Theme.accentWhite
                }
            }
        }

        Rectangle {
            visible: root.bookId <= 0
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            color: "transparent"

            Label {
                anchors.centerIn: parent
                text: "Оберіть книгу, щоб подивитися деталі"
                color: Theme.textSecondary
                font.pixelSize: 16
            }
        }

        ColumnLayout {
            visible: root.bookId > 0
            Layout.fillWidth: true
            spacing: Theme.spacingXL

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingXXL
                Layout.rightMargin: Theme.spacingXXL
                spacing: Theme.spacingXXL

                Rectangle {
                    Layout.preferredWidth: Theme.bookCoverWidth
                    Layout.preferredHeight: Theme.bookCoverHeight
                    color: "#111"
                    radius: Theme.radiusSharp
                    clip: true

                    Image {
                        id: coverImage
                        anchors.fill: parent
                        source: {
                            var p = bookDetailsModel.coverImagePath
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
                        visible: coverImage.status === Image.Ready
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "?"
                        font.pixelSize: 48
                        color: Theme.textSecondary
                        visible: coverImage.status !== Image.Ready
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    Label {
                        Layout.fillWidth: true
                        text: bookDetailsModel.title
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 42
                        color: Theme.textPrimary
                        wrapMode: Text.Wrap
                    }

                    Label {
                        Layout.fillWidth: true
                        text: (bookDetailsModel.authors || "Невідомий автор").toUpperCase()
                        font.family: Theme.fontCaption.family
                        font.pixelSize: 12
                        font.letterSpacing: 1
                        color: Theme.textMuted
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        spacing: Theme.spacingL

                        Label {
                            text: "Жанр: " + (bookDetailsModel.genre || "-")
                            color: Theme.textSecondary
                            font.pixelSize: 14
                        }

                        Label {
                            text: "Мова: " + (bookDetailsModel.language || "-")
                            color: Theme.textSecondary
                            font.pixelSize: 14
                        }
                    }

                    RowLayout {
                        spacing: Theme.spacingM

                        StarRating {
                            rating: Math.round(bookDetailsModel.averageRating)
                            maximumRating: 5
                            interactive: false
                            starSize: 20
                        }

                        Label {
                            text: Number(bookDetailsModel.averageRating).toFixed(1)
                            color: Theme.textSecondary
                            font.pixelSize: 14
                        }
                    }

                    Label {
                        text: "UAH " + Number(bookDetailsModel.price).toFixed(2)
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 24
                        color: Theme.textPrimary
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: Theme.spacingL
                        rowSpacing: Theme.spacingS

                        Label { text: "Видавець:"; color: Theme.textMuted; font.pixelSize: 12 }
                        Label { text: bookDetailsModel.publisherName || "-"; color: Theme.textSecondary; font.pixelSize: 12 }

                        Label { text: "Дата видання:"; color: Theme.textMuted; font.pixelSize: 12 }
                        Label { text: bookDetailsModel.publicationDate || "-"; color: Theme.textSecondary; font.pixelSize: 12 }

                        Label { text: "Сторінок:"; color: Theme.textMuted; font.pixelSize: 12 }
                        Label { text: bookDetailsModel.pageCount > 0 ? bookDetailsModel.pageCount : "-"; color: Theme.textSecondary; font.pixelSize: 12 }

                        Label { text: "ISBN:"; color: Theme.textMuted; font.pixelSize: 12 }
                        Label { text: bookDetailsModel.isbn || "-"; color: Theme.textSecondary; font.pixelSize: 12 }
                    }

                    RowLayout {
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 210
                            height: 46
                            color: addToCartArea.containsMouse && bookDetailsModel.stockQuantity > 0 ? Theme.accentWhite : "transparent"
                            border.color: bookDetailsModel.stockQuantity > 0 ? Theme.accentWhite : Theme.borderLight
                            border.width: 1
                            radius: Theme.radiusSharp
                            opacity: bookDetailsModel.stockQuantity > 0 ? 1.0 : 0.5

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }

                            Label {
                                anchors.centerIn: parent
                                text: bookDetailsModel.stockQuantity > 0 ? "Додати в кошик" : "Немає в наявності"
                                font.family: Theme.fontBody.family
                                font.pixelSize: 12
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 1
                                color: addToCartArea.containsMouse && bookDetailsModel.stockQuantity > 0 ? Theme.bgBody : Theme.textPrimary
                            }

                            MouseArea {
                                id: addToCartArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: bookDetailsModel.stockQuantity > 0
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (!(appContext && appContext.loggedIn)) {
                                        root.feedbackError = true
                                        root.feedbackMessage = "Щоб додати книгу в кошик, увійдіть у профіль"
                                        appContext.navigateTo("profile")
                                        return
                                    }
                                    cartModel.addItem(root.bookId)
                                }
                            }
                        }

                        Label {
                            text: bookDetailsModel.stockQuantity > 0 ? "В наявності" : "Немає на складі"
                            color: bookDetailsModel.stockQuantity > 0 ? Theme.success : Theme.error
                            font.pixelSize: 13
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingXXL
                Layout.rightMargin: Theme.spacingXXL
                spacing: Theme.spacingS

                Label {
                    text: "Опис"
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                    color: Theme.textPrimary
                }

                Label {
                    Layout.fillWidth: true
                    text: bookDetailsModel.description || "Опис відсутній"
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
                    text: "Залишити відгук"
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                    color: Theme.textPrimary
                }

                RowLayout {
                    spacing: Theme.spacingM

                    Label {
                        text: "Ваша оцінка:"
                        color: Theme.textSecondary
                        font.pixelSize: 14
                    }

                    StarRating {
                        id: editorRating
                        rating: root.selectedRating
                        maximumRating: 5
                        interactive: true
                        starSize: 20
                        onRatingSelected: root.selectedRating = newRating
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 130
                    color: "transparent"
                    border.color: Theme.borderLight
                    border.width: 1
                    radius: Theme.radiusSoft

                    TextArea {
                        id: commentInput
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        placeholderText: "Напишіть ваш відгук про цю книгу"
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        wrapMode: TextArea.Wrap
                        selectByMouse: true
                        font.family: Theme.fontBody.family
                        font.pixelSize: 14
                        background: Rectangle { color: "transparent" }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    Rectangle {
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 46
                        color: sendArea.containsMouse ? Theme.accentWhite : "transparent"
                        border.color: Theme.accentWhite
                        border.width: 1
                        radius: Theme.radiusSharp
                        opacity: (commentInput.text.trim().length > 0 && appContext.currentCustomerId > 0) ? 1.0 : 0.5

                        Behavior on color {
                            ColorAnimation { duration: Theme.animationFast }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "Надіслати відгук"
                            font.family: Theme.fontBody.family
                            font.pixelSize: 12
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1
                            color: sendArea.containsMouse ? Theme.bgBody : Theme.textPrimary
                        }

                        MouseArea {
                            id: sendArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: commentInput.text.trim().length > 0 && appContext.currentCustomerId > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                            onClicked: {
                                var ok = bookDetailsModel.submitComment(appContext.currentCustomerId, commentInput.text, root.selectedRating)
                                root.feedbackError = !ok
                                root.feedbackMessage = ok
                                        ? "Відгук успішно додано"
                                        : "Не вдалося додати відгук"
                                if (ok) {
                                    commentInput.text = ""
                                    root.selectedRating = 5
                                }
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: root.feedbackMessage.length > 0
                        text: root.feedbackMessage
                        color: root.feedbackError ? Theme.error : Theme.success
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }

                Rectangle {
                    visible: !(appContext && appContext.loggedIn)
                    Layout.topMargin: 6
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 46
                    color: loginForCommentArea.containsMouse ? Theme.accentWhite : "transparent"
                    border.color: Theme.accentWhite
                    border.width: 1
                    radius: Theme.radiusSharp

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Увійти, щоб залишити відгук"
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1
                        color: loginForCommentArea.containsMouse ? Theme.bgBody : Theme.textPrimary
                    }

                    MouseArea {
                        id: loginForCommentArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appContext.navigateTo("profile")
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingXXL
                Layout.rightMargin: Theme.spacingXXL
                spacing: Theme.spacingM

                Label {
                    text: "Відгуки"
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                    color: Theme.textPrimary
                }

                Label {
                    visible: bookDetailsModel.comments.length === 0
                    text: "Ще немає відгуків"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                }

                Repeater {
                    model: bookDetailsModel.comments

                    CommentItem {
                        width: parent ? parent.width : 400
                        authorName: modelData.authorName
                        commentDate: modelData.commentDate
                        rating: modelData.rating
                        commentText: modelData.commentText
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingXXL
                Layout.rightMargin: Theme.spacingXXL
                spacing: Theme.spacingM

                Label {
                    text: "Схожі книги"
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 24
                    color: Theme.textPrimary
                }

                Flow {
                    id: similarBooksFlow
                    Layout.fillWidth: true
                    width: Math.max(0, root.availableWidth - Theme.spacingXXL * 2)
                    spacing: Theme.spacingXL
                    flow: Flow.LeftToRight

                    Repeater {
                        model: bookDetailsModel.similarBooks

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
                                    root.feedbackError = true
                                    root.feedbackMessage = "Щоб додати книгу в кошик, увійдіть у профіль"
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

