import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// The main work area: heading, filters and the grid of optimisation cards.
Item {
    id: root
    
    property bool entranceReady: false
    signal applyRequested(string entryId)
    signal helpRequested(string entryId)
    signal filterRequested(string key)
    signal clearFiltersRequested()

    property int columnCount: width >= 1260 ? 3 : (width >= 1000 ? 2 : 1)
    property int cardGap: Theme.space.lg

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.layout.contentPadding
        anchors.rightMargin: Theme.layout.contentPadding
        anchors.topMargin: Theme.space.xxl
        anchors.bottomMargin: Theme.space.lg
        spacing: Theme.space.lg

        // ---------------------------------------------------------- heading
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: headingColumn.implicitHeight

                ColumnLayout {
                    id: headingColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 2
                    
                    opacity: root.entranceReady ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

                    ScrambleText {
                        objectName: "viewTitle"
                        Layout.fillWidth: true
                        text: controller.viewTitle
                        color: Theme.color.text
                        fontSize: Theme.font.size.display
                        speed: 40
                    }


                Text {
                    Layout.fillWidth: true
                    text: controller.viewSubtitle
                    color: Theme.color.textFaint
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.label
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }

        // ---------------------------------------------------------- filters
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm + 2

            Repeater {
                model: controller.filters

                FilterChip {
                    required property var modelData
                    text: modelData.label
                    selected: modelData.key === controller.activeFilter
                    onClicked: {
                        controller.playSound("click")
                        root.filterRequested(modelData.key)
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // ------------------------------------------------------------ grid
        GridView {
            id: grid
            objectName: "cardGrid"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: controller.entries
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 600

            cellWidth: Math.floor((grid.width - (root.columnCount - 1) * root.cardGap) / root.columnCount)
            cellHeight: Theme.layout.cardHeight + 28

            // A new category, search or filter starts at the top of the list.
            Connections {
                target: controller
                function onViewChanged() {
                    grid.contentY = 0
                }
            }

            delegate: TweakCard {
                required property var modelData
                width: grid.cellWidth
                height: Theme.layout.cardHeight + 20
                entry: modelData
                logoSource: modelData.logo ? (Assets.logos[modelData.logo] || "") : ""
                onApplyRequested: function(entryId) { root.applyRequested(entryId) }
                onHelpRequested: function(entryId) { root.helpRequested(entryId) }
            }

            ScrollBar.vertical: ScrollBar {
                id: gridScroll
                policy: ScrollBar.AsNeeded
                x: grid.width - width - Theme.space.md
                y: 0
                height: grid.height
                contentItem: Rectangle {
                    implicitWidth: 5
                    radius: 2.5
                    color: gridScroll.pressed ? Theme.color.text
                                             : (gridScroll.hovered ? Theme.color.textDim
                                                                  : Util.withAlpha(Theme.color.textDim, 0.55))
                    opacity: gridScroll.policy === ScrollBar.AlwaysOn || gridScroll.active ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.motion.base }
                    }
                }
                background: Rectangle {
                    color: "transparent"
                }
            }
        }

        // ------------------------------------------------------ empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: grid.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                width: 320
                spacing: Theme.space.lg

                IconGlyph {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "search"
                    glyphSize: 30
                    tint: Theme.color.textFaint
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Nothing matches this view"
                    color: Theme.color.text
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.title
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: controller.searchQuery.length > 0
                          ? "No entry matches \"" + controller.searchQuery + "\". Try a different word or clear the search."
                          : "No entry matches the selected filter."
                    color: Theme.color.textFaint
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.bodySmall
                }

                AppButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Reset the view"
                    variant: "secondary"
                    onClicked: {
                        controller.playSound("click")
                        root.clearFiltersRequested()
                    }
                }
            }
        }
    }
}
