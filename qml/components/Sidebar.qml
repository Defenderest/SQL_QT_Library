import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

Rectangle {
    id: root

    property string currentPage: "home"

    signal navigate(string page)

    width: Math.max(100, Math.min(120, parent.width / 12))
    height: parent.height
    color: Theme.glassPanel

    Label {
        id: logo
        anchors.top: parent.top
        anchors.topMargin: 80
        anchors.horizontalCenter: parent.horizontalCenter
        text: "LIBRARY"
        font.family: Theme.fontDisplayItalic.family
        font.pixelSize: 24
        font.italic: true
        color: Theme.textPrimary
        opacity: 0.8
        rotation: -90
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: 180
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacingM

        NavItem {
            iconSource: "qrc:/icons/home.png"
            tooltip: "\u0413\u043e\u043b\u043e\u0432\u043d\u0430"
            active: root.currentPage === "home"
            onClicked: root.navigate("home")
        }

        NavItem {
            iconSource: "qrc:/icons/book.png"
            tooltip: "\u041a\u043e\u043b\u0435\u043a\u0446\u0456\u044f"
            active: root.currentPage === "books"
            onClicked: root.navigate("books")
        }

        NavItem {
            iconSource: "qrc:/icons/users.png"
            tooltip: "\u0410\u0432\u0442\u043e\u0440\u0438"
            active: root.currentPage === "authors"
            onClicked: root.navigate("authors")
        }

        NavItem {
            iconSource: "qrc:/icons/shopping-bag.png"
            tooltip: "\u0406\u0441\u0442\u043e\u0440\u0456\u044f"
            active: root.currentPage === "orders"
            onClicked: root.navigate("orders")
        }

        NavItem {
            iconSource: "qrc:/icons/edit.png"
            tooltip: "\u0410\u0434\u043c\u0456\u043d"
            active: root.currentPage === "admin"
            visible: appContext && appContext.isAdmin
            onClicked: root.navigate("admin")
        }

        NavItem {
            iconSource: "qrc:/icons/user.png"
            tooltip: "\u041f\u0440\u043e\u0444\u0456\u043b\u044c"
            active: root.currentPage === "profile"
            onClicked: root.navigate("profile")
        }

        NavItem {
            iconSource: "qrc:/icons/cart.png"
            tooltip: "\u041a\u043e\u0448\u0438\u043a"
            active: root.currentPage === "cart"
            showBadge: cartModel && cartModel.totalItems > 0
            badgeCount: cartModel ? cartModel.totalItems : 0
            onClicked: root.navigate("cart")
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Theme.borderLight
    }

    component NavItem: Rectangle {
        property string iconSource: ""
        property string tooltip: ""
        property bool active: false
        property bool showBadge: false
        property int badgeCount: 0
        signal clicked()

        width: 40
        height: 40
        radius: width / 2
        color: active ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: -30
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 20
            color: Theme.accentWhite
            visible: parent.active
        }

        Image {
            anchors.centerIn: parent
            width: 16
            height: 16
            source: parent.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: parent.active ? 1.0 : 0.6

            Behavior on opacity {
                NumberAnimation { duration: Theme.animationFast }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            width: 18
            height: 18
            radius: 9
            color: Theme.accentWhite
            visible: parent.showBadge

            Label {
                anchors.centerIn: parent
                text: parent.parent.badgeCount
                font.bold: true
                color: Theme.bgBody
            }
        }

        Label {
            id: tooltipLabel
            anchors.left: parent.right
            anchors.leftMargin: Theme.spacingL
            anchors.verticalCenter: parent.verticalCenter
            text: parent.tooltip
            color: Theme.bgBody
            opacity: 0
            visible: opacity > 0

            background: Rectangle {
                color: Theme.accentWhite
                radius: Theme.radiusSharp
            }

            padding: Theme.spacingM

            Behavior on opacity {
                NumberAnimation { duration: Theme.animationFast }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: tooltipLabel.opacity = 1
            onExited: tooltipLabel.opacity = 0
            onClicked: parent.clicked()
        }
    }
}
