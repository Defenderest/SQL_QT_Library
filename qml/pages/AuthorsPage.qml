import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"
import ".."

ScrollView {
    id: root

    contentWidth: availableWidth
    contentHeight: contentColumn.height
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Component.onCompleted: {
        console.log("AuthorsPage loaded, loading authors...")
        authorModel.loadAllAuthors()
    }

    ColumnLayout {
        id: contentColumn
        width: parent.width
        spacing: 0

        // Отступ сверху
        Item { Layout.preferredHeight: 20 }

        // Сетка авторов - как в макете
        Flow {
            Layout.fillWidth: true
            Layout.margins: Theme.spacingXXL
            spacing: 40
            flow: Flow.LeftToRight

            Repeater {
                model: authorModel

                AuthorCard {
                    authorId: model.authorId
                    firstName: model.firstName
                    lastName: model.lastName
                    nationality: model.nationality
                    imagePath: model.imagePath

                    onClicked: function(authorId) {
                        appContext.navigateToAuthorDetails(authorId)
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Theme.spacingXXL }
    }
}
