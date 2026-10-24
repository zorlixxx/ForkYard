import QtQuick
import "../util.js" as Util

// A square icon button used for help, close and other secondary actions.
//
// Built from Rectangle + MouseArea instead of AbstractButton so rendering
// is fully under our control.
Rectangle {
    id: root

    property string iconName: ""
    property color tint: Theme.color.textDim
    property color hoverTint: Theme.color.text
    property string tooltipText: ""
    property int buttonSize: 30
    property bool quiet: false
    property real hoverScale: 1.0

    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize

    readonly property bool isHovered: mouseArea.containsMouse && !mouseArea.pressed && enabled
    readonly property bool isPressed: mouseArea.pressed && enabled

    color: {
        if (!enabled)
            return "transparent"
        if (isPressed)
            return Qt.rgba(1, 1, 1, 0.12)
        if (isHovered)
            return Qt.rgba(1, 1, 1, quiet ? 0.08 : 0.14)
        return Qt.rgba(1, 1, 1, 0.04)
    }
    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.hoverScale
        yScale: root.hoverScale
    }
    Behavior on hoverScale {
        NumberAnimation { duration: 350; easing.type: Easing.OutBounce }
    }
    border.width: 1
    border.color: isHovered ? Util.withAlpha(Theme.color.accent, 0.4) : Util.withAlpha("#ffffff", 0.10)
    radius: Theme.radius.control
    Behavior on color {
        ColorAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.5
        radius: parent.radius
        color: Util.withAlpha("#ffffff", 0.08)
        opacity: enabled ? (isHovered ? 1.0 : 0.6) : 0.2
        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
    }

    IconGlyph {
        iconName: root.iconName
        glyphSize: Math.round(root.buttonSize * 0.5)
        tint: {
            if (!enabled)
                return Theme.color.textFaint
            return root.isHovered ? root.hoverTint : root.tint
        }
        Behavior on tint {
            ColorAnimation { duration: Theme.motion.fast }
        }
        anchors.centerIn: parent
    }

    // Keyboard focus ring drawn just inside the button edge.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Theme.radius.control
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
        onEntered: { root.hoverScale = 1.15 }
        onExited: { root.hoverScale = 1.0 }
        onPressedChanged: {
            if (!pressed)
                root.clicked()
        }
    }

    Keys.enabled: root.enabled
    Keys.onPressed: {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.clicked()
    }
}
