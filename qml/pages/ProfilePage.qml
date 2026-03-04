import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ".."

ScrollView {
    id: root

    contentWidth: availableWidth
    contentHeight: contentColumn.height
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    property string saveMessage: ""
    property bool saveError: false
    property bool authFormVisible: false
    property bool registerMode: false
    property string authMessage: ""
    property bool authError: false

    Component.onCompleted: {
        if (appContext && appContext.loggedIn) {
            console.log("ProfilePage loaded, loading profile...")
            profileModel.loadProfile()
        }
    }

    Connections {
        target: appContext
        function onLoggedInChanged() {
            root.saveMessage = ""
            root.saveError = false
            root.authFormVisible = false
            root.authMessage = ""
            root.authError = false
            if (appContext && appContext.loggedIn) {
                profileModel.loadProfile()
            }
        }
    }

    Connections {
        target: profileModel
        function onErrorOccurred(message) {
            root.saveMessage = message
            root.saveError = true
        }
        function onProfileUpdated() {
            root.saveMessage = "Збережено"
            root.saveError = false
        }
    }

    ColumnLayout {
        id: contentColumn
        width: root.availableWidth
        spacing: 0

        Item { Layout.preferredHeight: 40 }

        Rectangle {
            visible: !(appContext && appContext.loggedIn)
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
            Layout.preferredHeight: root.authFormVisible ? 660 : 300
            color: Qt.rgba(1, 1, 1, 0.02)
            border.width: 1
            border.color: Theme.borderLight
            radius: Theme.radiusSoft

            Rectangle {
                visible: root.authFormVisible
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: Theme.spacingM
                anchors.topMargin: Theme.spacingM
                width: 34
                height: 34
                radius: 17
                color: authBackArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                border.width: 1
                border.color: Theme.borderLight

                Behavior on color {
                    ColorAnimation { duration: Theme.animationFast }
                }

                Label {
                    anchors.centerIn: parent
                    text: "<"
                    color: Theme.textPrimary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 16
                }

                MouseArea {
                    id: authBackArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.authFormVisible = false
                        root.authMessage = ""
                        root.authError = false
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, 460)
                spacing: Theme.spacingM

                Label {
                    width: parent.width
                    text: "Увійдіть у профіль"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 30
                }

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "У гостьовому режимі доступний перегляд книг, авторів і AI-чат. Для кошика, замовлень та відгуків увійдіть або створіть акаунт."
                    color: Theme.textSecondary
                    font.family: Theme.fontBody.family
                    font.pixelSize: 13
                }

                Rectangle {
                    visible: !root.authFormVisible
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 250
                    height: 46
                    radius: Theme.radiusRound
                    border.width: 1
                    border.color: Theme.accentWhite
                    color: revealAuthArea.containsMouse ? Theme.accentWhite : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animationFast }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "Войти в аккаунт"
                        color: revealAuthArea.containsMouse ? Theme.bgBody : Theme.textPrimary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 12
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.4
                    }

                    MouseArea {
                        id: revealAuthArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.authFormVisible = true
                            root.registerMode = false
                            root.authMessage = ""
                            root.authError = false
                        }
                    }
                }

                Column {
                    visible: root.authFormVisible
                    width: parent.width
                    spacing: Theme.spacingM

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Rectangle {
                            width: 140
                            height: 38
                            radius: Theme.radiusRound
                            border.width: 1
                            border.color: root.registerMode ? Theme.borderLight : Theme.accentWhite
                            color: root.registerMode ? "transparent" : Qt.rgba(1, 1, 1, 0.08)

                            Label {
                                anchors.centerIn: parent
                                text: "Вхід"
                                color: Theme.textPrimary
                                font.family: Theme.fontBody.family
                                font.pixelSize: 11
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 1.2
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.registerMode = false
                                    root.authMessage = ""
                                    root.authError = false
                                }
                            }
                        }

                        Rectangle {
                            width: 140
                            height: 38
                            radius: Theme.radiusRound
                            border.width: 1
                            border.color: root.registerMode ? Theme.accentWhite : Theme.borderLight
                            color: root.registerMode ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                            Label {
                                anchors.centerIn: parent
                                text: "Реєстрація"
                                color: Theme.textPrimary
                                font.family: Theme.fontBody.family
                                font.pixelSize: 11
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 1.2
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.registerMode = true
                                    root.authMessage = ""
                                    root.authError = false
                                }
                            }
                        }
                    }

                    TextField {
                        id: guestFirstNameField
                        visible: root.registerMode
                        width: parent.width
                        height: 50
                        placeholderText: "Ім'я"
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 13
                        leftPadding: Theme.spacingM
                        rightPadding: Theme.spacingM
                        selectionColor: Qt.rgba(1, 1, 1, 0.2)
                        background: Rectangle {
                            radius: Theme.radiusSoft
                            color: guestFirstNameField.activeFocus ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.02)
                            border.width: 1
                            border.color: guestFirstNameField.activeFocus ? Theme.accentWhite : Theme.borderLight

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                        }
                    }

                    TextField {
                        id: guestLastNameField
                        visible: root.registerMode
                        width: parent.width
                        height: 50
                        placeholderText: "Прізвище"
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 13
                        leftPadding: Theme.spacingM
                        rightPadding: Theme.spacingM
                        selectionColor: Qt.rgba(1, 1, 1, 0.2)
                        background: Rectangle {
                            radius: Theme.radiusSoft
                            color: guestLastNameField.activeFocus ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.02)
                            border.width: 1
                            border.color: guestLastNameField.activeFocus ? Theme.accentWhite : Theme.borderLight

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                        }
                    }

                    TextField {
                        id: guestEmailField
                        width: parent.width
                        height: 50
                        placeholderText: "Email"
                        inputMethodHints: Qt.ImhEmailCharactersOnly
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 13
                        leftPadding: Theme.spacingM
                        rightPadding: Theme.spacingM
                        selectionColor: Qt.rgba(1, 1, 1, 0.2)
                        background: Rectangle {
                            radius: Theme.radiusSoft
                            color: guestEmailField.activeFocus ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.02)
                            border.width: 1
                            border.color: guestEmailField.activeFocus ? Theme.accentWhite : Theme.borderLight

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                        }
                    }

                    TextField {
                        id: guestPhoneField
                        visible: root.registerMode
                        width: parent.width
                        height: 50
                        placeholderText: "Телефон (+380XXXXXXXXX)"
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        font.family: Theme.fontBody.family
                        font.pixelSize: 13
                        leftPadding: Theme.spacingM
                        rightPadding: Theme.spacingM
                        selectionColor: Qt.rgba(1, 1, 1, 0.2)
                        background: Rectangle {
                            radius: Theme.radiusSoft
                            color: guestPhoneField.activeFocus ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.02)
                            border.width: 1
                            border.color: guestPhoneField.activeFocus ? Theme.accentWhite : Theme.borderLight

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                        }
                    }

                    TextField {
                        id: guestPasswordField
                        width: parent.width
                        height: 50
                        placeholderText: "Пароль"
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        echoMode: TextInput.Password
                        font.family: Theme.fontBody.family
                        font.pixelSize: 13
                        leftPadding: Theme.spacingM
                        rightPadding: Theme.spacingM
                        selectionColor: Qt.rgba(1, 1, 1, 0.2)
                        background: Rectangle {
                            radius: Theme.radiusSoft
                            color: guestPasswordField.activeFocus ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.02)
                            border.width: 1
                            border.color: guestPasswordField.activeFocus ? Theme.accentWhite : Theme.borderLight

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                        }
                    }

                    TextField {
                        id: guestConfirmPasswordField
                        visible: root.registerMode
                        width: parent.width
                        height: 50
                        placeholderText: "Підтвердіть пароль"
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        echoMode: TextInput.Password
                        font.family: Theme.fontBody.family
                        font.pixelSize: 13
                        leftPadding: Theme.spacingM
                        rightPadding: Theme.spacingM
                        selectionColor: Qt.rgba(1, 1, 1, 0.2)
                        background: Rectangle {
                            radius: Theme.radiusSoft
                            color: guestConfirmPasswordField.activeFocus ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.02)
                            border.width: 1
                            border.color: guestConfirmPasswordField.activeFocus ? Theme.accentWhite : Theme.borderLight

                            Behavior on color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: Theme.animationFast }
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 250
                        height: 46
                        radius: Theme.radiusRound
                        border.width: 1
                        border.color: Theme.accentWhite
                        color: submitArea.containsMouse ? Theme.accentWhite : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.animationFast }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: root.registerMode ? "Створити акаунт" : "Увійти"
                            color: submitArea.containsMouse ? Theme.bgBody : Theme.textPrimary
                            font.family: Theme.fontBody.family
                            font.pixelSize: 12
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1.4
                        }

                        MouseArea {
                            id: submitArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var ok = false
                                if (root.registerMode) {
                                    ok = appContext.registerWithCredentials(
                                                guestFirstNameField.text,
                                                guestLastNameField.text,
                                                guestEmailField.text,
                                                guestPhoneField.text,
                                                guestPasswordField.text,
                                                guestConfirmPasswordField.text)
                                } else {
                                    ok = appContext.loginWithCredentials(guestEmailField.text, guestPasswordField.text)
                                }

                                if (ok) {
                                    root.authError = false
                                    root.authMessage = "Успішно"
                                    guestPasswordField.text = ""
                                    guestConfirmPasswordField.text = ""
                                } else {
                                    root.authError = true
                                    root.authMessage = appContext.authError
                                }
                            }
                        }
                    }

                }

                Label {
                    width: parent.width
                    visible: root.authFormVisible && root.authMessage.length > 0
                    text: root.authMessage
                    horizontalAlignment: Text.AlignHCenter
                    color: root.authError ? Theme.error : Theme.success
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }

        RowLayout {
            visible: appContext && appContext.loggedIn
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
            Layout.bottomMargin: 40
            spacing: 30

            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                radius: 40
                color: "#222"

                Label {
                    anchors.centerIn: parent
                    text: ""
                }
            }

            ColumnLayout {
                spacing: 4

                Label {
                    text: (profileModel.firstName + " " + profileModel.lastName).trim()
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 32
                    color: Theme.textPrimary
                }

                Label {
                    text: profileModel.loyaltyProgram ? "ПРЕМІУМ УЧАСНИК" : "УЧАСНИК"
                    font.family: Theme.fontCaption.family
                    font.pixelSize: 12
                    font.letterSpacing: 1
                    color: Theme.textMuted
                }
            }
        }

        GridLayout {
            visible: appContext && appContext.loggedIn
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingXXL
            Layout.rightMargin: Theme.spacingXXL
            Layout.maximumWidth: 800
            columns: 2
            columnSpacing: 40
            rowSpacing: 24

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Ім'я"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                TextField {
                    id: firstNameField
                    Layout.fillWidth: true
                    text: profileModel.firstName
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: firstNameField.activeFocus ? Theme.accentWhite : Theme.borderLight
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Прізвище"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                TextField {
                    id: lastNameField
                    Layout.fillWidth: true
                    text: profileModel.lastName
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: lastNameField.activeFocus ? Theme.accentWhite : Theme.borderLight
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Електронна пошта"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                TextField {
                    id: emailField
                    Layout.fillWidth: true
                    text: profileModel.email
                    readOnly: true
                    color: Theme.textSecondary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Theme.borderLight
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Телефон"
                    font.family: Theme.fontBody.family
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                TextField {
                    id: phoneField
                    Layout.fillWidth: true
                    text: profileModel.phone
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay.family
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: phoneField.activeFocus ? Theme.accentWhite : Theme.borderLight
                        }
                    }
                }
            }
        }

        Rectangle {
            id: saveButton
            visible: appContext && appContext.loggedIn
            Layout.topMargin: 50
            Layout.leftMargin: Theme.spacingXXL
            width: 220
            height: 46
            color: saveArea.containsMouse ? Theme.accentWhite : "transparent"
            border.color: Theme.accentWhite
            border.width: 1
            radius: Theme.radiusSharp

            Behavior on color {
                ColorAnimation { duration: Theme.animationFast }
            }

            Label {
                anchors.centerIn: parent
                text: "Зберегти зміни"
                font.family: Theme.fontBody.family
                font.pixelSize: 12
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                color: saveArea.containsMouse ? Theme.bgBody : Theme.textPrimary
            }

            MouseArea {
                id: saveArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    profileModel.updateProfile(
                                firstNameField.text,
                                lastNameField.text,
                                phoneField.text,
                                profileModel.address)
                }
            }
        }

        Rectangle {
            visible: appContext && appContext.loggedIn
            Layout.topMargin: 14
            Layout.leftMargin: Theme.spacingXXL
            width: 220
            height: 46
            color: logoutArea.containsMouse ? Theme.accentWhite : "transparent"
            border.color: Theme.accentWhite
            border.width: 1
            radius: Theme.radiusSharp

            Behavior on color {
                ColorAnimation { duration: Theme.animationFast }
            }

            Label {
                anchors.centerIn: parent
                text: "Вийти з акаунта"
                font.family: Theme.fontBody.family
                font.pixelSize: 12
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                color: logoutArea.containsMouse ? Theme.bgBody : Theme.textPrimary
            }

            MouseArea {
                id: logoutArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: appContext.logout()
            }
        }

        Label {
            visible: (appContext && appContext.loggedIn) && text.length > 0
            Layout.topMargin: 12
            Layout.leftMargin: Theme.spacingXXL
            text: root.saveMessage
            color: root.saveError ? Theme.error : Theme.success
            font.pixelSize: 12
        }

        Item { Layout.preferredHeight: Theme.spacingXXL }
    }
}
