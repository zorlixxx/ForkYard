import QtQuick
import "../util.js" as Util
import QtQuick.Layouts

// A reliable, self-contained button used across dialogs and the main UI.
//
// Built from Rectangle + MouseArea instead of AbstractButton so rendering
// is fully under our control: no inherited theme styles, no native widget
// quirks, no clipping or focus-ring artifacts.  Four variants share one
// implementation:
//   primary   - filled with the accent colour
//   secondary - quiet surface with a hairline border
//   ghost     - text only, used inside cards and dialogs
//   danger    - destructive actions
Rectangle {
    id: root

    property string variant: "primary"
    property string text: ""
    property string iconName: ""
    property color accentColor: Theme.color.accent
    property int buttonPadding: Theme.space.xl
    property int controlHeight: 34
    property real tiltX: 0
    property real tiltY: 0
    property real maxTilt: 3

    readonly property bool isPrimary: variant === "primary"
    readonly property bool isGhost: variant === "ghost"
    readonly property bool isDanger: variant === "danger"
    readonly property bool isSecondary: variant === "secondary"

    signal clicked()

    implicitHeight: controlHeight
    implicitWidth: row.implicitWidth + buttonPadding * 2

    readonly property color accentHiColor: isDanger ? "#f08a80" : Theme.color.accentHi
    readonly property color accentLoColor: isDanger ? "#b94b44" : Theme.color.accentLo

    readonly property bool isHovered: mouseArea.containsMouse && !mouseArea.pressed && enabled
    readonly property bool isPressed: mouseArea.pressed && enabled
    // A small lift on hover, a small dip when it is pressed.
    property real liftScale: 1.0
    property real parallaxX: 0
    property real parallaxY: 0

    // ------------------------------------------------------------- surface
    // Glassmorphism surface: translucent fill, hairline border, top
    // highlight.  The blur is faked with a translucent plate so it stays
    // cheap and never blocks the event loop.
    color: {
        if (!enabled)
            return Qt.rgba(1, 1, 1, 0.04)
        if (isPrimary)
            return isPressed ? Util.withAlpha(accentColor, 0.72)
                             : (isHovered ? Util.withAlpha(accentColor, 0.92)
                                          : Util.withAlpha(accentColor, 0.80))
        if (isSecondary)
            return isPressed ? Qt.rgba(1, 1, 1, 0.10)
                             : (isHovered ? Qt.rgba(1, 1, 1, 0.12)
                                          : Qt.rgba(1, 1, 1, 0.06))
        return isPressed ? Qt.rgba(1, 1, 1, 0.08)
                         : (isHovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
    }
    border.width: 1
    border.color: {
        if (isPrimary)
            return isHovered ? Util.withAlpha("#ffffff", 0.35) : Util.withAlpha("#ffffff", 0.22)
        return isHovered ? Util.withAlpha(Theme.color.accent, 0.45) : Util.withAlpha("#ffffff", 0.12)
    }
    radius: Theme.radius.control
    Behavior on color {
        ColorAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.motion.fast }
    }

    // The button keeps its three dimensional tilt.  Every layer of it
    // has the shape of the button, so the edges never look sliced.
    transform: [
        Translate { x: root.parallaxX; y: root.parallaxY },
        Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: root.liftScale
            yScale: root.liftScale
        },
        Rotation { origin.x: root.width/2; origin.y: root.height/2; axis { x: 1; y: 0; z: 0 } angle: root.tiltX },
        Rotation { origin.x: root.width/2; origin.y: root.height/2; axis { x: 0; y: 1; z: 0 } angle: root.tiltY }
    ]
    Behavior on tiltX { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on tiltY { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on parallaxX { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on parallaxY { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on liftScale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // The sheen of the glass.  It has the shape of the button, so the
    // tilt never cuts a corner out of it.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Util.withAlpha("#ffffff", isPrimary ? 0.22 : 0.10) }
            GradientStop { position: 0.5; color: Util.withAlpha("#ffffff", isPrimary ? 0.07 : 0.03) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: enabled ? (isHovered ? 1.0 : 0.75) : 0.3
        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
    }

    // ------------------------------------------------------------- contents
    Row {
        id: row
        spacing: Theme.space.md
        anchors.centerIn: parent

        IconGlyph {
            visible: root.iconName !== ""
            iconName: root.iconName
            glyphSize: 15
            tint: {
                if (!enabled)
                    return Theme.color.textFaint
                if (isPrimary)
                    return "#ffffff"
                if (isDanger)
                    return isHovered ? Theme.color.advanced : Theme.color.textDim
                return Theme.color.text
            }
            anchors.verticalCenter: parent.verticalCenter
            Behavior on tint {
                ColorAnimation { duration: Theme.motion.fast }
            }
        }

        Text {
            id: label
            text: root.text
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.label + 1
            font.weight: Font.DemiBold
            color: {
                if (!enabled)
                    return Theme.color.textFaint
                if (isPrimary)
                    return "#ffffff"
                if (isDanger)
                    return isHovered ? Theme.color.advanced : Theme.color.textDim
                return Theme.color.text
            }
            Behavior on color {
                ColorAnimation { duration: Theme.motion.fast }
            }
        }
    }

    // ------------------------------------------------------------- focus ring
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

    // ------------------------------------------------------------- input
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            root.liftScale = 1.025
        }
        onPositionChanged: {
            var cx = mouse.x - width / 2
            var cy = mouse.y - height / 2
            root.tiltY = -(cx / Math.max(width,1)) * root.maxTilt
            root.tiltX = (cy / Math.max(height,1)) * root.maxTilt
            root.parallaxX = cx * 0.08
            root.parallaxY = cy * 0.08
        }
        onExited: {
            root.liftScale = 1.0
            root.tiltX = 0
            root.tiltY = 0
            root.parallaxX = 0
            root.parallaxY = 0
        }
        onPressedChanged: {
            root.liftScale = pressed ? 0.97 : (containsMouse ? 1.025 : 1.0)
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
