import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
import QtQuick.Window 2.15

ApplicationWindow {
    id: root

    visible: true
    // Р Р°Р·РјРµСЂ РѕРєРЅР° РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
    width: 1500
    height: 800
    minimumWidth: 900
    minimumHeight: 600

    // Р¦РµРЅС‚СЂРёСЂСѓРµРј РѕРєРЅРѕ РЅР° СЌРєСЂР°РЅРµ
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2

    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint

    title: "OBSIDIAN.LUXE | BookStore"
    color: Theme.bgBody

    // РЎРІРѕР№СЃС‚РІР°
    property int currentCustomerId: appContext ? appContext.currentCustomerId : -1
    property string currentPage: "home"
    property int selectedBookId: 0
    property int selectedAuthorId: 0

    // РђРґР°РїС‚РёРІРЅС‹Рµ СЃРІРѕР№СЃС‚РІР° - РјР°СЃС€С‚Р°Р±РёСЂСѓРµРј РєРѕРЅС‚РµРЅС‚ РїРѕРґ СЂР°Р·РјРµСЂ РѕРєРЅР°
    property real contentScale: Math.min(width / 1280, height / 800)
    property bool isCompact: width < 1100 || height < 700
    property bool isMobile: width < 900

    function applyGlobalBookSearch() {
        var searchQuery = searchField.text.trim()

        if (root.currentPage !== "books") {
            root.currentPage = "books"
            root.replacePage("books")
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

    function getPageSource(page) {
        switch(page) {
            case "home": return "qrc:/pages/HomePage.qml"
            case "books": return "qrc:/pages/BooksPage.qml"
            case "bookDetails": return "qrc:/pages/BookDetailsPage.qml"
            case "authors": return "qrc:/pages/AuthorsPage.qml"
            case "authorDetails": return "qrc:/pages/AuthorDetailsPage.qml"
            case "cart": return "qrc:/pages/CartPage.qml"
            case "orders": return "qrc:/pages/OrdersPage.qml"
            case "admin": return "qrc:/pages/AdminPage.qml"
            case "profile": return "qrc:/pages/ProfilePage.qml"
            default: return "qrc:/pages/HomePage.qml"
        }
    }

    function getPageProperties(page) {
        if (page === "bookDetails") {
            return { "bookId": root.selectedBookId }
        }
        if (page === "authorDetails") {
            return { "authorId": root.selectedAuthorId }
        }
        return {}
    }

    function replacePage(page) {
        var source = getPageSource(page)
        var props = getPageProperties(page)
        stackView.replace(source, props)
    }

    Component.onCompleted: {
        console.log("Main window loaded, current page:", currentPage)
        console.log("Screen size:", Screen.width, "x", Screen.height)
        console.log("Window position:", x, y)
        console.log("StackView current item:", stackView.currentItem)
    }

    // РЁСЂРёС„С‚ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
    font.family: Theme.fontBody.family

    // Р“Р»Р°РІРЅС‹Р№ layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Р‘РѕРєРѕРІР°СЏ РїР°РЅРµР»СЊ (Dock)
        Sidebar {
            id: sidebar
            Layout.fillHeight: true
            currentPage: root.currentPage
            onNavigate: function(page) {
                if (root.currentPage !== page) {
                    root.currentPage = page
                    root.replacePage(page)
                }
            }
        }

        // РљРѕРЅС‚РµРЅС‚РЅР°СЏ РѕР±Р»Р°СЃС‚СЊ
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Р’РµСЂС…РЅСЏСЏ РїР°РЅРµР»СЊ (Header)
            Rectangle {
                Layout.fillWidth: true
                // РЈРІРµР»РёС‡РµРЅРЅР°СЏ РІС‹СЃРѕС‚Р° header
                height: 120
                color: "transparent"

                // РќРёР¶РЅСЏСЏ РіСЂР°РЅРёС†Р°
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

                    // Р—Р°РіРѕР»РѕРІРѕРє СЃС‚СЂР°РЅРёС†С‹
                    Label {
                        id: pageTitle
                        text: {
                            switch(root.currentPage) {
                                case "home": return "\u0413\u043e\u043b\u043e\u0432\u043d\u0430"
                                case "books": return "\u041a\u043e\u043b\u0435\u043a\u0446\u0456\u044f"
                                case "authors": return "\u0410\u0432\u0442\u043e\u0440\u0438"
                                case "orders": return "\u0406\u0441\u0442\u043e\u0440\u0456\u044f"
                                case "admin": return "\u0410\u0434\u043c\u0456\u043d \u043f\u0430\u043d\u0435\u043b\u044c"
                                case "profile": return "\u041f\u0440\u043e\u0444\u0456\u043b\u044c"
                                case "cart": return "\u041a\u043e\u0448\u0438\u043a"
                                case "bookDetails": return "\u041a\u043d\u0438\u0433\u0430"
                                case "authorDetails":
                                    return (authorDetailsModel && authorDetailsModel.fullName && authorDetailsModel.fullName.length > 0)
                                            ? authorDetailsModel.fullName
                                            : "\u0410\u0432\u0442\u043e\u0440"
                                default: return ""
                            }
                        }
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 48
                        color: Theme.textPrimary
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    // РџРѕРёСЃРє
                    TextField {
                        id: searchField
                        Layout.preferredWidth: 300
                        Layout.preferredHeight: 50
                        placeholderText: "\u041f\u043e\u0448\u0443\u043a..."
                        placeholderTextColor: Theme.textSecondary
                        color: Theme.textPrimary
                        verticalAlignment: Text.AlignVCenter

                        background: Rectangle {
                            color: "transparent"

                            // РќРёР¶РЅСЏСЏ РіСЂР°РЅРёС†Р°
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
                            if (text.trim().length === 0 && root.currentPage === "books") {
                                bookModel.loadAllBooks()
                            }
                        }
                    }
                }
            }

            // РћР±Р»Р°СЃС‚СЊ СЃС‚СЂР°РЅРёС†
            StackView {
                id: stackView
                Layout.fillWidth: true
                Layout.fillHeight: true

                // РСЃРїРѕР»СЊР·СѓРµРј Loader РґР»СЏ РѕС‚Р»РѕР¶РµРЅРЅРѕР№ Р·Р°РіСЂСѓР·РєРё
                initialItem: "qrc:/pages/HomePage.qml"

                replaceEnter: Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Theme.animationSmooth
                    }
                }

                replaceExit: Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Theme.animationSmooth
                    }
                }
            }

            // Fallback - РїРѕРєР°Р·С‹РІР°РµРј РµСЃР»Рё StackView РїСѓСЃС‚РѕР№
            Rectangle {
                visible: stackView.currentItem === null
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgBody

                Column {
                    anchors.centerIn: parent
                    spacing: 20

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\u0417\u0430\u0432\u0430\u043d\u0442\u0430\u0436\u0435\u043d\u043d\u044f..."
                        font.pixelSize: 24
                        color: Theme.textPrimary
                    }

                    Rectangle {
                        id: progressBar
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 200
                        height: 4
                        color: Theme.borderLight
                        radius: 2

                        Rectangle {
                            id: progressIndicator
                            width: progressBar.width * 0.6
                            height: progressBar.height
                            color: Theme.accentWhite
                            radius: 2

                            SequentialAnimation on x {
                                loops: Animation.Infinite
                                NumberAnimation { from: 0; to: progressBar.width - progressIndicator.width; duration: 1000 }
                                NumberAnimation { from: progressBar.width - progressIndicator.width; to: 0; duration: 1000 }
                            }
                        }
                    }
                }
            }
        }
    }

    // Р¤СѓРЅРєС†РёСЏ РЅР°РІРёРіР°С†РёРё (РІС‹Р·С‹РІР°РµС‚СЃСЏ РёР· C++)
    function navigateToPage(pageName) {
        console.log("Navigating to:", pageName)
        root.replacePage(pageName)
    }

    // РћР±СЂР°Р±РѕС‚РєР° РЅР°РІРёРіР°С†РёРё РѕС‚ AppContext
    Connections {
        target: appContext
        function onNavigateToPage(page) {
            console.log("Navigate to page signal:", page)
            if (root.currentPage !== page) {
                root.currentPage = page
                root.replacePage(page)
            }
        }
    }
}
