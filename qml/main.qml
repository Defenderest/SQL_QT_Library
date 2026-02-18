import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
import "pages"
import QtQuick.Window 2.15

ApplicationWindow {
    id: root

    visible: true
    // Размер окна по умолчанию
    width: 1500
    height: 800
    minimumWidth: 900
    minimumHeight: 600

    // Центрируем окно на экране
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2

    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint

    title: "OBSIDIAN.LUXE | BookStore"
    color: Theme.bgBody

    // Свойства
    property int currentCustomerId: appContext ? appContext.currentCustomerId : -1
    property string currentPage: "home"

    // Адаптивные свойства - масштабируем контент под размер окна
    property real contentScale: Math.min(width / 1280, height / 800)
    property bool isCompact: width < 1100 || height < 700
    property bool isMobile: width < 900

    Component.onCompleted: {
        console.log("Main window loaded, current page:", currentPage)
        console.log("Screen size:", Screen.width, "x", Screen.height)
        console.log("Window position:", x, y)
        console.log("StackView current item:", stackView.currentItem)
    }

    // Шрифт по умолчанию
    font.family: Theme.fontBody.family

    // Главный layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Боковая панель (Dock)
        Sidebar {
            id: sidebar
            Layout.fillHeight: true
            currentPage: root.currentPage
            onNavigate: function(page) {
                if (root.currentPage !== page) {
                    root.currentPage = page
                    stackView.replace(getPageComponent(page))
                }
            }
        }

        // Контентная область
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Верхняя панель (Header)
            Rectangle {
                Layout.fillWidth: true
                // Увеличенная высота header
                height: 120
                color: "transparent"

                // Нижняя граница
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

                    // Заголовок страницы
                    Label {
                        id: pageTitle
                        text: {
                            switch(root.currentPage) {
                                case "home": return "Головна"
                                case "books": return "Колекція"
                                case "authors": return "Автори"
                                case "orders": return "Історія"
                                case "profile": return "Профіль"
                                case "cart": return "Кошик"
                                default: return ""
                            }
                        }
                        font.family: Theme.fontDisplay.family
                        font.pixelSize: 48
                        color: Theme.textPrimary
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    // Поиск
                    TextField {
                        id: searchField
                        Layout.preferredWidth: 300
                        Layout.preferredHeight: 50
                        placeholderText: "Пошук..."
                        placeholderTextColor: Theme.textSecondary
                        color: Theme.textPrimary
                        verticalAlignment: Text.AlignVCenter

                        background: Rectangle {
                            color: "transparent"

                            // Нижняя граница
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
                            console.log("Search:", text)
                        }
                    }
                }
            }

            // Область страниц
            StackView {
                id: stackView
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Используем Loader для отложенной загрузки
                initialItem: HomePage {}

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

            // Fallback - показываем если StackView пустой
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
                        text: "Завантаження..."
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

    // Компоненты страниц для навигации
    Component { id: homePageComponent; HomePage {} }
    Component { id: booksPageComponent; BooksPage {} }
    Component { id: authorsPageComponent; AuthorsPage {} }
    Component { id: cartPageComponent; CartPage {} }
    Component { id: ordersPageComponent; OrdersPage {} }
    Component { id: profilePageComponent; ProfilePage {} }

    // Функция получения компонента страницы
    function getPageComponent(page) {
        switch(page) {
            case "home": return homePageComponent
            case "books": return booksPageComponent
            case "authors": return authorsPageComponent
            case "cart": return cartPageComponent
            case "orders": return ordersPageComponent
            case "profile": return profilePageComponent
            default: return homePageComponent
        }
    }

    // Функция навигации (вызывается из C++)
    function navigateToPage(pageName) {
        console.log("Navigating to:", pageName)
        var component = getPageComponent(pageName)
        if (component && stackView.currentItem !== component) {
            stackView.replace(component)
        }
    }

    // Обработка навигации от AppContext
    Connections {
        target: appContext
        function onNavigateToPage(page) {
            console.log("Navigate to page signal:", page)
            if (root.currentPage !== page) {
                root.currentPage = page
                var component = getPageComponent(page)
                if (component) {
                    stackView.replace(component)
                }
            }
        }
    }
}
