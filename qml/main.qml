import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
import QtQuick.Window 2.15

ApplicationWindow {
    id: root

    visible: true
    width: 1500
    height: 800
    minimumWidth: 900
    minimumHeight: 600

    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint

    title: "Library"
    color: Theme.bgBody
    
    // Центрування вікна
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2

    property int currentCustomerId: appContext ? appContext.currentCustomerId : -1
    property string currentPage: "home"
    property int selectedBookId: 0
    property int selectedAuthorId: 0

    // Lazy cache flags (page instance is kept after first load)
    property bool homeLoaded: true
    property bool booksLoaded: false
    property bool bookDetailsLoaded: false
    property bool authorsLoaded: false
    property bool authorDetailsLoaded: false
    property bool cartLoaded: false
    property bool ordersLoaded: false
    property bool adminLoaded: false
    property bool profileLoaded: false
    property bool warmupDone: false

    property real contentScale: Math.min(width / 1280, height / 800)
    property bool isCompact: width < 1100 || height < 700
    property bool isMobile: width < 900
    property var searchSuggestions: []
    property bool searchSuggestionsVisible: false
    property int searchSuggestionLimit: 8
    property bool suppressSearchSuggestionRefresh: false

    function hideSearchSuggestions() {
        searchSuggestTimer.stop()
        searchSuggestionsVisible = false
        searchSuggestions = []
    }

    function refreshSearchSuggestions() {
        var query = searchField.text.trim()
        if (!appContext || query.length < 2) {
            hideSearchSuggestions()
            return
        }

        var suggestions = appContext.getSearchSuggestions(query, searchSuggestionLimit)
        searchSuggestions = suggestions
        searchSuggestionsVisible = searchField.activeFocus && suggestions.length > 0
    }

    function openSearchSuggestion(item) {
        if (!item || !appContext) {
            return
        }

        var targetId = Number(item.id)
        if (!isFinite(targetId) || targetId <= 0) {
            return
        }

        suppressSearchSuggestionRefresh = true
        searchField.text = item.displayText || searchField.text
        suppressSearchSuggestionRefresh = false
        hideSearchSuggestions()

        if (item.type === "book") {
            root.selectedBookId = targetId
            root.navigateToPage("bookDetails")
        } else if (item.type === "author") {
            root.selectedAuthorId = targetId
            root.navigateToPage("authorDetails")
        }
    }

    function resolveSuggestionImageSource(path) {
        if (!path || path.length === 0) {
            return ""
        }

        if (path.indexOf("qrc:/") === 0 || path.indexOf("file:///") === 0 ||
                path.indexOf("http://") === 0 || path.indexOf("https://") === 0) {
            return path
        }

        return "file:///" + path.replace(/\\/g, "/")
    }

    function applyGlobalBookSearch() {
        var searchQuery = searchField.text.trim()
        hideSearchSuggestions()

        if (root.currentPage !== "books") {
            root.currentPage = "books"
            root.navigateToPage("books")
            Qt.callLater(function() {
                if (searchQuery.length === 0) {
                    bookModel.loadAllBooks()
                } else {
                    bookModel.searchBooks(searchQuery)
                }
            })
            return
        }

        if (searchQuery.length === 0) {
            bookModel.loadAllBooks()
        } else {
            bookModel.searchBooks(searchQuery)
        }
    }

    function resolveAccessiblePage(page) {
        if (page === "cart" || page === "orders") {
            if (!(appContext && appContext.loggedIn)) {
                return "profile"
            }
            return page
        }

        if (page === "admin") {
            if (appContext && appContext.isAdmin) {
                return "admin"
            }
            return (appContext && appContext.loggedIn) ? "home" : "profile"
        }

        return page
    }

    function ensurePageLoaded(page) {
        switch (page) {
            case "home": homeLoaded = true; break
            case "books": booksLoaded = true; break
            case "bookDetails": bookDetailsLoaded = true; break
            case "authors": authorsLoaded = true; break
            case "authorDetails": authorDetailsLoaded = true; break
            case "cart": cartLoaded = true; break
            case "orders": ordersLoaded = true; break
            case "admin": adminLoaded = true; break
            case "profile": profileLoaded = true; break
            default: homeLoaded = true; break
        }
    }

    function pageToIndex(page) {
        switch (page) {
            case "home": return 0
            case "books": return 1
            case "bookDetails": return 2
            case "authors": return 3
            case "authorDetails": return 4
            case "cart": return 5
            case "orders": return 6
            case "admin": return 7
            case "profile": return 8
            default: return 0
        }
    }

    function applyPageProperties(page) {
        if (page === "bookDetails" && bookDetailsLoader.item) {
            bookDetailsLoader.item.bookId = root.selectedBookId
        }
        if (page === "authorDetails" && authorDetailsLoader.item) {
            authorDetailsLoader.item.authorId = root.selectedAuthorId
        }
    }

    function warmupCommonPages() {
        if (warmupDone) {
            return
        }
        warmupDone = true
        Qt.callLater(function() { booksLoaded = true })
        Qt.callLater(function() { authorsLoaded = true })
        Qt.callLater(function() { profileLoaded = true })
    }

    function navigateToPage(page) {
        hideSearchSuggestions()
        page = resolveAccessiblePage(page)
        ensurePageLoaded(page)

        if (root.currentPage !== page) {
            root.currentPage = page
        }

        applyPageProperties(page)
    }

    // Backward compatibility
    function replacePage(page) {
        navigateToPage(page)
    }

    Timer {
        id: searchSuggestTimer
        interval: 140
        repeat: false
        onTriggered: root.refreshSearchSuggestions()
    }

    Timer {
        id: searchBlurHideTimer
        interval: 120
        repeat: false
        onTriggered: root.hideSearchSuggestions()
    }

    Component.onCompleted: {
        // Центрування вікна (безпечно, без binding loop)
        x = Screen.width / 2 - width / 2
        y = Screen.height / 2 - height / 2
        
        console.log("Main window loaded with optimized navigation")
        // Load home page on start
        Qt.callLater(function() {
            navigateToPage("home")
            warmupCommonPages()
        })
    }

    font.family: Theme.fontBody.family

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.fillHeight: true
            currentPage: root.currentPage
            onNavigate: function(page) {
                root.navigateToPage(page)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                id: headerBar
                Layout.fillWidth: true
                height: 120
                color: "transparent"
                clip: false
                z: 300

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Theme.borderLight
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingXXL
                    anchors.rightMargin: Theme.spacingXXL
                    anchors.topMargin: 35
                    anchors.bottomMargin: 35
                    spacing: Theme.spacingXL

                    Label {
                        id: pageTitle
                        text: {
                            switch(root.currentPage) {
                                case "home": return "Головна"
                                case "books": return "Колекція"
                                case "authors": return "Автори"
                                case "orders": return "Історія"
                                case "admin": return "Адмін панель"
                                case "profile": return "Профіль"
                                case "cart": return "Кошик"
                                case "bookDetails": return "Книга"
                                case "authorDetails":
                                    return (authorDetailsModel && authorDetailsModel.fullName && authorDetailsModel.fullName.length > 0)
                                            ? authorDetailsModel.fullName
                                            : "Автор"
                                default: return ""
                            }
                        }
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 48
                        color: Theme.textPrimary
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    Item {
                        id: searchFieldContainer
                        Layout.preferredWidth: 320
                        Layout.preferredHeight: 50
                        z: 320

                        TextField {
                            id: searchField
                            anchors.fill: parent
                            placeholderText: "Пошук книг та авторів..."
                            placeholderTextColor: Theme.textSecondary
                            color: Theme.textPrimary
                            verticalAlignment: TextInput.AlignVCenter

                            background: Rectangle {
                                color: "transparent"
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 1
                                    color: searchField.activeFocus ? Theme.textPrimary : Theme.borderLight
                                }
                            }

                            font.family: Theme.fontBody.family
                            font.pixelSize: 14

                            onAccepted: {
                                root.applyGlobalBookSearch()
                            }

                            onTextChanged: {
                                if (root.suppressSearchSuggestionRefresh) {
                                    return
                                }

                                if (text.trim().length === 0) {
                                    root.hideSearchSuggestions()
                                    if (root.currentPage === "books") {
                                        bookModel.loadAllBooks()
                                    }
                                    return
                                }

                                searchSuggestTimer.restart()
                            }

                            onActiveFocusChanged: {
                                if (activeFocus && text.trim().length >= 2) {
                                    searchBlurHideTimer.stop()
                                    searchSuggestTimer.restart()
                                } else if (!activeFocus) {
                                    searchBlurHideTimer.restart()
                                }
                            }

                            Keys.onEscapePressed: root.hideSearchSuggestions()
                        }

                        Rectangle {
                            id: searchSuggestionsPopup
                            visible: root.searchSuggestionsVisible
                            anchors.top: parent.bottom
                            anchors.topMargin: 10
                            anchors.left: parent.left
                            anchors.right: parent.right
                            z: 340
                            radius: Theme.radiusSoft
                            color: Qt.rgba(0.02, 0.02, 0.02, 0.98)
                            border.width: 1
                            border.color: Theme.borderLight
                            implicitHeight: Math.min(300, suggestionsColumn.implicitHeight + 10)
                            clip: true

                            ScrollView {
                                id: suggestionsScroll
                                anchors.fill: parent
                                anchors.margins: 4
                                clip: true
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                contentWidth: availableWidth

                                Column {
                                    id: suggestionsColumn
                                    width: suggestionsScroll.availableWidth
                                    spacing: 2

                                    Repeater {
                                        model: root.searchSuggestions

                                        Rectangle {
                                            width: parent.width
                                            height: 58
                                            radius: Theme.radiusSoft
                                            color: suggestionArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 10

                                                Rectangle {
                                                    Layout.preferredWidth: 34
                                                    Layout.preferredHeight: 34
                                                    radius: 6
                                                    color: Qt.rgba(1, 1, 1, 0.04)
                                                    border.width: 1
                                                    border.color: Theme.borderLight

                                                    Image {
                                                        anchors.fill: parent
                                                        anchors.margins: 1
                                                        visible: modelData.imagePath && modelData.imagePath.length > 0
                                                        source: root.resolveSuggestionImageSource(modelData.imagePath || "")
                                                        fillMode: Image.PreserveAspectCrop
                                                        smooth: true
                                                        clip: true
                                                    }

                                                    Label {
                                                        anchors.centerIn: parent
                                                        visible: !(modelData.imagePath && modelData.imagePath.length > 0)
                                                        text: modelData.type === "book" ? "B" : "A"
                                                        color: Theme.textSecondary
                                                        font.family: Theme.fontCaption.family
                                                        font.pixelSize: 10
                                                        font.capitalization: Font.AllUppercase
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Label {
                                                        Layout.fillWidth: true
                                                        text: modelData.displayText || ""
                                                        color: Theme.textPrimary
                                                        font.family: Theme.fontBody.family
                                                        font.pixelSize: 13
                                                        elide: Text.ElideRight
                                                    }

                                                    Label {
                                                        Layout.fillWidth: true
                                                        text: modelData.type === "book"
                                                              ? ("Книга • " + Number(modelData.price || 0).toFixed(2) + " грн")
                                                              : "Автор"
                                                        color: Theme.textMuted
                                                        font.family: Theme.fontCaption.family
                                                        font.pixelSize: 10
                                                        font.capitalization: Font.AllUppercase
                                                        font.letterSpacing: 0.8
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                id: suggestionArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onPressed: searchBlurHideTimer.stop()
                                                onClicked: root.openSearchSuggestion(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackLayout {
                    id: pageStack
                    anchors.fill: parent
                    currentIndex: root.pageToIndex(root.currentPage)

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: homeLoader
                            anchors.fill: parent
                            active: root.homeLoaded
                            source: "qrc:/pages/HomePage.qml"
                            asynchronous: false
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: booksLoader
                            anchors.fill: parent
                            active: root.booksLoaded
                            source: "qrc:/pages/BooksPage.qml"
                            asynchronous: root.currentPage !== "books"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: bookDetailsLoader
                            anchors.fill: parent
                            active: root.bookDetailsLoaded
                            source: "qrc:/pages/BookDetailsPage.qml"
                            asynchronous: false
                            onLoaded: {
                                if (item) {
                                    item.bookId = root.selectedBookId
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: authorsLoader
                            anchors.fill: parent
                            active: root.authorsLoaded
                            source: "qrc:/pages/AuthorsPage.qml"
                            asynchronous: root.currentPage !== "authors"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: authorDetailsLoader
                            anchors.fill: parent
                            active: root.authorDetailsLoaded
                            source: "qrc:/pages/AuthorDetailsPage.qml"
                            asynchronous: false
                            onLoaded: {
                                if (item) {
                                    item.authorId = root.selectedAuthorId
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: cartLoader
                            anchors.fill: parent
                            active: root.cartLoaded
                            source: "qrc:/pages/CartPage.qml"
                            asynchronous: false
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: ordersLoader
                            anchors.fill: parent
                            active: root.ordersLoaded
                            source: "qrc:/pages/OrdersPage.qml"
                            asynchronous: root.currentPage !== "orders"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: adminLoader
                            anchors.fill: parent
                            active: root.adminLoaded
                            source: "qrc:/pages/AdminPage.qml"
                            asynchronous: root.currentPage !== "admin"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Loader {
                            id: profileLoader
                            anchors.fill: parent
                            active: root.profileLoaded
                            source: "qrc:/pages/ProfilePage.qml"
                            asynchronous: root.currentPage !== "profile"
                        }
                    }
                }
            }
        }
    }

    AiChatWidget {
        id: aiChat
    }

    Connections {
        target: appContext
        function onNavigateToPage(page) {
            console.log("Navigate to page signal:", page)
            root.navigateToPage(page)
        }
    }
}
