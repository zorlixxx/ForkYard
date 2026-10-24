import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// The left hand column: safety controls and the category navigation.
Item {
    id: root
    objectName: "sidebar"

    signal categoryRequested(string name)
    signal restorePointRequested()
    signal elevationRequested()
    signal toggleRequested()

    property bool expanded: true

    // The sound only plays when the user folds the column, never while
    // the interface is still starting up.
    property bool _live: false

    onExpandedChanged: {
        if (!_live)
            return
        if (expanded) controller.playSound("unfold left menu")
        else controller.playSound("fold left menu")
    }

    Component.onCompleted: _live = true

    implicitWidth: Theme.layout.sidebarWidth

    // The column is a sheet of glass, the background flows through it.
    GlassPanel {
        anchors.fill: parent
        radius: 0
        tint: Theme.color.accent
        shadow: false
        grain: true
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Util.withAlpha("#ffffff", 0.10)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space.lg
        anchors.rightMargin: Theme.space.lg
        anchors.topMargin: Theme.space.xl
        anchors.bottomMargin: Theme.space.lg
        spacing: Theme.space.lg

        // ------------------------------------------------- privilege state
        Rectangle {
            id: privilegeBox
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: Theme.radius.control
            color: Util.withAlpha(controller.isAdmin ? Theme.color.safe : Theme.color.moderate, 0.07)
            border.width: 1
            border.color: Util.withAlpha(controller.isAdmin ? Theme.color.safe : Theme.color.moderate, 0.26)
            Behavior on color { ColorAnimation { duration: Theme.motion.base } }
            Behavior on border.color { ColorAnimation { duration: Theme.motion.base } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space.lg
                anchors.rightMargin: Theme.space.lg
                spacing: Theme.space.md

                // The state is a light that breathes.
                Rectangle {
                    Layout.preferredWidth: 7
                    Layout.preferredHeight: 7
                    radius: 3.5
                    color: controller.isAdmin ? Theme.color.safe : Theme.color.moderate
                    opacity: 1.0

                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 1400; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: controller.isAdmin ? "Running as administrator" : "Standard user rights"
                    color: controller.isAdmin ? Theme.color.text : Theme.color.textDim
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.label
                    elide: Text.ElideRight
                }

                AppButton {
                    visible: !controller.isAdmin
                    objectName: "elevateButton"
                    text: "Elevate"
                    variant: "ghost"
                    controlHeight: 24
                    buttonPadding: Theme.space.md
                    onClicked: root.elevationRequested()
                }
            }
        }

        // -------------------------------------------------- category list
        Text {
            Layout.leftMargin: Theme.space.xs
            Layout.topMargin: Theme.space.xs
            text: "CATEGORIES"
            color: Theme.color.textFaint
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.micro
            font.weight: Font.DemiBold
            font.letterSpacing: Theme.font.tracking.micro
        }

        ListView {
            id: categoryList
            objectName: "categoryList"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: controller.categories
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 200

            delegate: NavItem {
                required property var modelData
                required property int index

                objectName: "nav-" + modelData.name
                width: categoryList.width
                iconName: modelData.icon
                label: modelData.name
                count: modelData.count
                selected: modelData.name === controller.currentCategory
                           && controller.searchQuery.length === 0
                onClicked: {
                    controller.playSound("categories")
                    root.categoryRequested(modelData.name)
                }
            }

            ScrollBar.vertical: ScrollBar {
                id: categoryScroll
                policy: ScrollBar.AsNeeded
                x: categoryList.width - width - Theme.space.sm
                y: 0
                height: categoryList.height
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: categoryScroll.pressed ? Theme.color.textFaint
                                                 : (categoryScroll.hovered ? Theme.color.textDim : Theme.color.borderHi)
                    opacity: categoryScroll.policy === ScrollBar.AlwaysOn || categoryScroll.active ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.motion.base }
                    }
                }
                background: Rectangle {
                    color: "transparent"
                }
            }
        }

        // ------------------------------------------------------ utilities
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.color.border
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm

            AppButton {
                Layout.fillWidth: true
                objectName: "restorePointButton"
                text: "Create restore point"
                iconName: "heart"
                variant: "ghost"
                controlHeight: 32
                buttonPadding: Theme.space.lg
                onClicked: {
                    controller.playSound("restore-point-create")
                    root.restorePointRequested()
                }
            }

            IconButton {
                objectName: "sidebarCollapseButton"
                iconName: "chevron-left"
                buttonSize: 32
                quiet: true
                tint: Theme.color.textFaint
                hoverTint: Theme.color.accent
                onClicked: root.toggleRequested()
            }
        }
    }
}
