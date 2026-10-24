import QtQuick
import QtQuick.Layouts
import "../util.js" as Util

// A filter toggle used above the card grid.
Rectangle {
    id: root

    property bool selected: false
    property string glyph: ""
    property int count: -1
    property string text: ""

    signal clicked()

    implicitHeight: 28
    implicitWidth: row.implicitWidth + Theme.space.xl

    readonly property bool isHovered: mouseArea.containsMouse && !mouseArea.pressed && enabled

    color: selected ? Util.withAlpha(Theme.color.accent, 0.20)
                    : (isHovered ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04))
    radius: Theme.radius.pill
    border.width: 1
    border.color: selected ? Util.withAlpha(Theme.color.accent, 0.55) : Theme.color.border
    Behavior on color {
        ColorAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.motion.fast }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space.sm + 1

        IconGlyph {
            visible: root.glyph !== ""
            iconName: root.glyph
            glyphSize: 12
            tint: root.selected ? Theme.color.accent : Theme.color.textFaint
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            color: root.selected ? Theme.color.accent
                                : (root.isHovered ? Theme.color.text : Theme.color.textDim)
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.label
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color {
                ColorAnimation { duration: Theme.motion.fast }
            }
        }

        Text {
            visible: root.count >= 0
            text: root.count
            color: root.selected ? Util.withAlpha(Theme.color.accent, 0.8) : Theme.color.textFaint
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.micro
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Keyboard focus ring.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Theme.radius.pill + 1
        color: "transparent"
        border.width: 2
        border.color: Theme.color.accent
        opacity: root.activeFocus ? 0.85 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: Theme.motion.instant }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Keys.enabled: root.enabled
    Keys.onPressed: {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.clicked()
    }
}
