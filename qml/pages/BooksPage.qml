import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"
import ".."

Item {
    id: root

    property bool filterPanelOpen: false

    // РЎРІРѕР№СЃС‚РІР° С„РёР»СЊС‚СЂРѕРІ
    property string selectedGenre: ""
    property string selectedLanguage: ""
    property double minPrice: -1
    property double maxPrice: -1
    property var genreOptions: ["\u0412\u0441\u0456"]
    property var languageOptions: ["\u0411\u0443\u0434\u044c-\u044f\u043a\u0430"]
    property int filterPanelPadding: Math.max(14, Math.min(Theme.spacingXXL, Math.floor(root.height * 0.03)))
    property int filterPanelSectionSpacing: Math.max(12, Math.floor(root.height * 0.02))

    onFilterPanelOpenChanged: {
        console.log("Filter panel state changed to:", filterPanelOpen)
    }

    // Р¤СѓРЅРєС†РёСЏ РїСЂРёРјРµРЅРµРЅРёСЏ С„РёР»СЊС‚СЂРѕРІ
    function applyFilters() {
        var parsedMin = minPriceInput.text.trim() === "" ? -1 : parseFloat(minPriceInput.text)
        var parsedMax = maxPriceInput.text.trim() === "" ? -1 : parseFloat(maxPriceInput.text)

        minPrice = isNaN(parsedMin) ? -1 : parsedMin
        maxPrice = isNaN(parsedMax) ? -1 : parsedMax

        console.log("Applying filters - Genre:", selectedGenre, "Language:", selectedLanguage,
                    "Price:", minPrice, "-", maxPrice)

        if (selectedGenre === "" && selectedLanguage === "" && minPrice < 0 && maxPrice < 0) {
            bookModel.loadAllBooks()
            return
        }

        bookModel.loadFilteredBooks(
            selectedGenre,
            selectedLanguage,
            minPrice,
            maxPrice,
            false
        )
    }

    Component.onCompleted: {
        console.log("BooksPage loaded, filterPanelOpen:", filterPanelOpen)
        var dbGenres = bookModel.getAvailableGenres()
        if (dbGenres && dbGenres.length > 0) {
            genreOptions = ["\u0412\u0441\u0456"].concat(dbGenres)
        }
        var dbLanguages = bookModel.getAvailableLanguages()
        if (dbLanguages && dbLanguages.length > 0) {
            languageOptions = ["\u0411\u0443\u0434\u044c-\u044f\u043a\u0430"].concat(dbLanguages)
        }

        if (bookModel.count === 0) {
            bookModel.loadAllBooks()
        }
        // РџСЂРёРЅСѓРґРёС‚РµР»СЊРЅРѕ Р·Р°РєСЂС‹РІР°РµРј РїР°РЅРµР»СЊ РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃ РЅРµР±РѕР»СЊС€РѕР№ Р·Р°РґРµСЂР¶РєРѕР№
        Qt.callLater(function() {
            filterPanelOpen = false
            console.log("Filter panel force closed")
        })
    }

    // ScrollView СЃ РєРѕРЅС‚РµРЅС‚РѕРј
    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.rightMargin: root.filterPanelOpen ? Theme.filterPanelWidth : 0

        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
        }

        contentWidth: availableWidth
        contentHeight: contentColumn.height
        clip: true
        // РћС‚РєР»СЋС‡Р°РµРј Р°РІС‚Рѕ-СЃРєСЂРѕР»Р» РїСЂРё С„РѕРєСѓСЃРµ
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentColumn
            width: scrollView.availableWidth
            spacing: 0

            // ========== CATALOG CONTROLS ==========
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingXXL
                Layout.topMargin: 30
                spacing: Theme.spacingM

                // Placeholder РґР»СЏ РєРЅРѕРїРєРё С„РёР»СЊС‚СЂР° (Р·Р°РЅРёРјР°РµС‚ РјРµСЃС‚Рѕ)
                Item {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 45
                }

                Item { Layout.fillWidth: true }

                // РЎС‡РµС‚С‡РёРє СЂРµР·СѓР»СЊС‚Р°С‚РѕРІ
                Label {
                    text: bookModel.count === 0 ? "\u041d\u0435\u043c\u0430\u0454 \u0440\u0435\u0437\u0443\u043b\u044c\u0442\u0430\u0442\u0456\u0432" :
                          bookModel.count === 1 ? "\u041f\u043e\u043a\u0430\u0437\u0430\u043d\u043e 1 \u0440\u0435\u0437\u0443\u043b\u044c\u0442\u0430\u0442" :
                          bookModel.count < 5 ? "\u041f\u043e\u043a\u0430\u0437\u0430\u043d\u043e " + bookModel.count + " \u0440\u0435\u0437\u0443\u043b\u044c\u0442\u0430\u0442\u0438" :
                                                "\u041f\u043e\u043a\u0430\u0437\u0430\u043d\u043e " + bookModel.count + " \u0440\u0435\u0437\u0443\u043b\u044c\u0442\u0430\u0442\u0456\u0432"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }
            }

            // ========== РЎР•РўРљРђ РљРќРР“ ==========
            // РСЃРїРѕР»СЊР·СѓРµРј Flow РІРјРµСЃС‚Рѕ GridLayout РґР»СЏ Р°РґР°РїС‚РёРІРЅРѕСЃС‚Рё РєР°Рє РІ РјР°РєРµС‚Рµ
            Flow {
                id: booksGrid
                Layout.fillWidth: true
                Layout.margins: Theme.spacingXXL
                Layout.topMargin: 40
                spacing: 40
                flow: Flow.LeftToRight

                Repeater {
                    model: bookModel

                    BookCard {
                        bookId: model.bookId
                        title: model.title
                        authors: model.authors
                        price: model.price
                        coverImagePath: model.coverImagePath
                        stockQuantity: model.stockQuantity
                        genre: model.genre

                        onClicked: function(bookId) {
                            appContext.navigateToBookDetails(bookId)
                        }

                        onAddToCart: function(bookId) {
                            if (!(appContext && appContext.loggedIn)) {
                                appContext.navigateTo("profile")
                                return
                            }
                            cartModel.addItem(bookId)
                        }
                    }
                }
            }

            // РћС‚СЃС‚СѓРї СЃРЅРёР·Сѓ
            Item { Layout.preferredHeight: Theme.spacingXXL }
        }
    }

    // ========== РљРќРћРџРљРђ Р¤Р†Р›Р¬РўР Р (РІРЅРµ ScrollView) ==========
    Rectangle {
        id: filterButton
        x: Math.min(Theme.spacingXXL, root.width / 20)
        y: 30
        width: filtersRow.implicitWidth + 40
        height: 45
        radius: Theme.radiusPill
        color: filtersArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
        border.color: Theme.borderLight
        border.width: 1
        z: 20

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        RowLayout {
            id: filtersRow
            anchors.centerIn: parent
            spacing: Theme.spacingM

            Image {
                source: "qrc:/icons/filter.png"
                sourceSize.width: 14
                sourceSize.height: 14
                width: 14
                height: 14
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Label {
                text: "\u0424\u0456\u043b\u044c\u0442\u0440\u0438"
                font.family: Theme.fontBody.family
                font.pixelSize: 12
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                color: Theme.textPrimary
            }
        }

        MouseArea {
            id: filtersArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                console.log("Filter button clicked, current state:", root.filterPanelOpen)
                root.filterPanelOpen = !root.filterPanelOpen
            }
        }
    }

    // ========== Р—РђРўР•РњРќР•РќРР• ==========
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#000000"
        opacity: root.filterPanelOpen ? 0.6 : 0
        visible: root.filterPanelOpen
        z: 5

        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.filterPanelOpen
            onClicked: {
                console.log("Overlay clicked, closing filter")
                root.filterPanelOpen = false
            }
        }
    }

    // ========== FILTER SIDEBAR ==========
    Rectangle {
        id: filterPanel
        z: 10
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: Theme.filterPanelWidth
        x: root.filterPanelOpen ? parent.width - width : parent.width

        Behavior on x {
            NumberAnimation { duration: Theme.animationSlow; easing.type: Easing.OutCubic }
        }

        // РџР°РЅРµР»СЊ РІРёРґРёРјР° С‚РѕР»СЊРєРѕ РєРѕРіРґР° filterPanelOpen == true
        visible: root.filterPanelOpen
        enabled: root.filterPanelOpen

        color: Theme.glassPanel
        border.color: Theme.borderLight
        border.width: 1

        // Р›РµРІР°СЏ РіСЂР°РЅРёС†Р°
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.borderLight
        }

        ScrollView {
            id: filterScroll
            anchors.fill: parent
            anchors.margins: root.filterPanelPadding
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            contentWidth: availableWidth
            contentHeight: filterContent.implicitHeight

            ColumnLayout {
            id: filterContent
            width: filterScroll.availableWidth
            spacing: root.filterPanelSectionSpacing

            // Р—Р°РіРѕР»РѕРІРѕРє
            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "\u0424\u0456\u043b\u044c\u0442\u0440\u0438"
                    font.family: Theme.fontDisplayItalic.family
                    font.pixelSize: 28
                    font.italic: true
                    color: Theme.textPrimary
                }

                Item { Layout.fillWidth: true }

                // РљРЅРѕРїРєР° Р·Р°РєСЂС‹С‚РёСЏ
                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "\u2715"
                        font.pixelSize: 20
                        color: closeArea.containsMouse ? Theme.textSecondary : Theme.textPrimary

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.filterPanelOpen = false
                    }
                }
            }

            // ========== Р–РђРќР  ==========
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                Label {
                    text: "\u0416\u0430\u043d\u0440"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: root.genreOptions

                        Rectangle {
                            id: genreRect
                            width: genreLabel.implicitWidth + 30
                            height: 36
                            radius: 18
                            color: genreArea.containsMouse || root.selectedGenre === modelData || (root.selectedGenre === "" && index === 0) ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                            border.color: root.selectedGenre === modelData || (root.selectedGenre === "" && index === 0) ? Theme.accentWhite : Theme.borderLight
                            border.width: 1

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            Label {
                                id: genreLabel
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontBody.family
                                font.pixelSize: 12
                                color: root.selectedGenre === modelData || (root.selectedGenre === "" && index === 0) ? Theme.textPrimary : "#aaa"
                            }

                            MouseArea {
                                id: genreArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.selectedGenre = index === 0 ? "" : modelData
                                    console.log("Selected genre:", root.selectedGenre)
                                }
                            }
                        }
                    }
                }
            }

            // ========== РњРћР’Рђ ==========
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                Label {
                    text: "\u041c\u043e\u0432\u0430"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: root.languageOptions

                        Rectangle {
                            id: langRect
                            width: langLabel.implicitWidth + 30
                            height: 36
                            radius: 18
                            color: langArea.containsMouse || root.selectedLanguage === modelData || (root.selectedLanguage === "" && index === 0) ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                            border.color: root.selectedLanguage === modelData || (root.selectedLanguage === "" && index === 0) ? Theme.accentWhite : Theme.borderLight
                            border.width: 1

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            Label {
                                id: langLabel
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontBody.family
                                font.pixelSize: 12
                                color: root.selectedLanguage === modelData || (root.selectedLanguage === "" && index === 0) ? Theme.textPrimary : "#aaa"
                            }

                            MouseArea {
                                id: langArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.selectedLanguage = index === 0 ? "" : modelData
                                    console.log("Selected language:", root.selectedLanguage)
                                }
                            }
                        }
                    }
                }
            }

            // ========== Р¦Р†РќРђ ==========
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                Label {
                    text: "\u0414\u0456\u0430\u043f\u0430\u0437\u043e\u043d \u0426\u0456\u043d\u0438 (UAH)"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Theme.textMuted
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    // Min price
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        color: "transparent"
                        border.color: Theme.borderLight
                        border.width: 1

                        TextInput {
                            id: minPriceInput
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: root.minPrice >= 0 ? root.minPrice.toString() : ""
                            font.family: Theme.fontDisplay.family
                            font.pixelSize: 16
                            color: Theme.textPrimary
                            selectByMouse: true
                            validator: DoubleValidator { bottom: 0; top: 999999; decimals: 2 }
                            onTextChanged: {
                                root.minPrice = text.trim() === "" ? -1 : (parseFloat(text) || -1)
                            }
                        }
                    }

                    // Line
                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 1
                        color: "#333"
                    }

                    // Max price
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        color: "transparent"
                        border.color: Theme.borderLight
                        border.width: 1

                        TextInput {
                            id: maxPriceInput
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: root.maxPrice >= 0 ? root.maxPrice.toString() : ""
                            font.family: Theme.fontDisplay.family
                            font.pixelSize: 16
                            color: Theme.textPrimary
                            selectByMouse: true
                            validator: DoubleValidator { bottom: 0; top: 999999; decimals: 2 }
                            onTextChanged: {
                                root.maxPrice = text.trim() === "" ? -1 : (parseFloat(text) || -1)
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Math.max(24, Math.floor(root.height * 0.05)) }

            // ========== РљРќРћРџРљРђ Р—РђРЎРўРћРЎРЈР’РђРўР ==========
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: applyArea.containsMouse ? Theme.accentWhite : "transparent"
                border.color: Theme.accentWhite
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: Theme.animationFast }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM

                    Label {
                        text: "\u0417\u0430\u0441\u0442\u043e\u0441\u0443\u0432\u0430\u0442\u0438"
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 2
                        color: applyArea.containsMouse ? Theme.bgBody : Theme.textPrimary
                    }
                }

                MouseArea {
                    id: applyArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.applyFilters()
                        root.filterPanelOpen = false
                    }
                }
            }

            // ========== РљРќРћРџРљРђ РЎРљРРќРЈРўР ==========
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: resetArea.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.2) : "transparent"
                border.color: Theme.error
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: Theme.animationFast }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM

                    Label {
                        text: "\u0421\u043a\u0438\u043d\u0443\u0442\u0438 \u0444\u0456\u043b\u044c\u0442\u0440\u0438"
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 2
                        color: resetArea.containsMouse ? Theme.error : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedGenre = ""
                        root.selectedLanguage = ""
                        root.minPrice = -1
                        root.maxPrice = -1
                        minPriceInput.text = ""
                        maxPriceInput.text = ""
                        bookModel.loadAllBooks()
                        root.filterPanelOpen = false
                    }
                }
            }
            }
        }
    }
}
