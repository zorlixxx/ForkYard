import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// The activity bar at the bottom of the window.
//
// It stays collapsed to a single line that shows the most recent message
// and expands into the full history on demand.
Item {
    id: root
    objectName: "activityPanel"

    property bool expanded: false

    onExpandedChanged: {
        if (expanded) controller.playSound("upactivitymenu")
        else controller.playSound("downactivitymenu")
    }

    signal clearRequested()

    implicitHeight: expanded ? Theme.layout.activityExpanded : Theme.layout.activityCollapsed
    function levelColor(level) {
        if (level === "error")
            return Theme.color.advanced
        if (level === "warn")
            return Theme.color.moderate
        if (level === "ok")
            return Theme.color.safe
        return Theme.color.textDim
    }

    Rectangle {
        anchors.fill: parent
        color: Util.withAlpha(Theme.color.bg, 0.72)
    }

    GlassPanel {
        anchors.fill: parent
        radius: 0
        tint: Theme.color.accent
        shadow: false
        grain: false
        borderGlow: false
        baseColor: Util.withAlpha(Theme.color.surface, 0.35)
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Util.withAlpha(Theme.color.accent, 0.18)
    }

    // ------------------------------------------------------- collapsed bar
    Item {
        id: strip
        anchors.fill: parent
        visible: !root.expanded

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            opacity: stripMouse.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.space.xxl
            anchors.rightMargin: Theme.space.xxl
            spacing: Theme.space.lg

            IconGlyph {
                id: chevron
                iconName: "chevron-up"
                glyphSize: 13
                tint: stripMouse.containsMouse ? Theme.color.accent : Theme.color.textFaint
                Behavior on tint { ColorAnimation { duration: Theme.motion.fast } }
                transform: Rotation {
                    origin.x: width / 2
                    origin.y: height / 2
                    angle: root.expanded ? 180 : 0
                    Behavior on angle {
                        NumberAnimation { duration: Theme.motion.base; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                text: "ACTIVITY"
                color: Theme.color.textFaint
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.micro
                font.weight: Font.DemiBold
                font.letterSpacing: Theme.font.tracking.micro
            }

            Rectangle {
                width: 1
                height: 12
                color: Theme.color.border
            }

            // The last message, with a mark in the colour of its level.
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 6
                Layout.preferredHeight: 6
                radius: 3
                color: root.levelColor(controller.logEntries.length > 0
                                       ? controller.logEntries[controller.logEntries.length - 1].level
                                       : "info")
                opacity: controller.logEntries.length > 0 ? 1.0 : 0.0
            }

            Text {
                id: lastMessage
                Layout.fillWidth: true
                text: controller.logEntries.length > 0
                      ? controller.logEntries[controller.logEntries.length - 1].text
                      : "No activity yet"
                color: controller.logEntries.length > 0
                       ? root.levelColor(controller.logEntries[controller.logEntries.length - 1].level)
                       : Theme.color.textFaint
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.label
                elide: Text.ElideRight

                // A new message slides into the bar.
                property string shown: text
                onShownChanged: messageAnimation.restart()
                transform: Translate { x: lastMessage.slideX }
                property real slideX: 0
                SequentialAnimation {
                    id: messageAnimation
                    ParallelAnimation {
                        NumberAnimation { target: lastMessage; property: "opacity"; from: 0.0; to: 1.0; duration: 320; easing.type: Easing.OutCubic }
                        NumberAnimation { target: lastMessage; property: "slideX"; from: -10; to: 0; duration: 320; easing.type: Easing.OutCubic }
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: countLabel.implicitWidth + Theme.space.lg
                implicitHeight: 18
                radius: Theme.radius.pill
                color: Util.withAlpha(Theme.color.textFaint, 0.14)

                Text {
                    id: countLabel
                    anchors.centerIn: parent
                    text: controller.logEntries.length
                    color: Theme.color.textFaint
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.micro
                }
            }
        }

        MouseArea {
            id: stripMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = true
        }
    }

    // --------------------------------------------------------- expanded log
    Item {
        anchors.fill: parent
        visible: root.expanded

        RowLayout {
            id: expandedHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.space.xxl
            anchors.rightMargin: Theme.space.xxl
            anchors.topMargin: Theme.space.md
            spacing: Theme.space.lg

            IconButton {
                objectName: "activityCollapseButton"
                iconName: "chevron-down"
                buttonSize: 22
                quiet: true
                tint: Theme.color.textFaint
                hoverTint: Theme.color.accent
                onClicked: root.expanded = false
            }

            Text {
                text: "ACTIVITY"
                color: Theme.color.textFaint
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.micro
                font.weight: Font.DemiBold
                font.letterSpacing: Theme.font.tracking.micro
            }

            Item {
                Layout.fillWidth: true
            }

                AppButton {
                    text: "Clear"
                    variant: "ghost"
                    controlHeight: 24
                    buttonPadding: Theme.space.md
                    onClicked: {
                        controller.playSound("erase")
                        root.clearRequested()
                    }
                }
        }

        ListView {
            id: logList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: expandedHeader.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: Theme.space.xxl
            anchors.rightMargin: Theme.space.xxl
            anchors.topMargin: Theme.space.sm
            anchors.bottomMargin: Theme.space.md
            clip: true
            model: controller.logEntries
            spacing: 1
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                required property var modelData
                width: logList.width
                height: logRow.implicitHeight

                // The row lights up while the pointer is on it.
                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -Theme.space.sm
                    anchors.rightMargin: -Theme.space.sm
                    radius: Theme.radius.sm
                    color: Util.withAlpha("#ffffff", 0.04)
                    opacity: rowMouse.containsMouse ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                RowLayout {
                    id: logRow
                    anchors.fill: parent
                    spacing: Theme.space.lg

                    Text {
                        Layout.preferredWidth: 58
                        text: modelData.time
                        color: Theme.color.textFaint
                        font.family: Theme.font.family.mono
                        font.pixelSize: Theme.font.size.mono
                    }

                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: root.levelColor(modelData.level)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.text
                        color: modelData.level === "info" ? Theme.color.textDim : root.levelColor(modelData.level)
                        font.family: Theme.font.family.ui
                        font.pixelSize: Theme.font.size.bodySmall
                        wrapMode: Text.WordWrap
                    }
                }
            }

            onCountChanged: positionViewAtEnd()
        }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.motion.base; easing.type: Easing.OutCubic }
    }
}
