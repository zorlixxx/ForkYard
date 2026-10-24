import QtQuick
import "../util.js" as Util

// Approximation of the React-Bits "ColorBends" animated background.
//
// The original is a WebGL shader; here it is rebuilt with layered,
// rotating color bands and slow parallax so it runs on the Qt renderer
// without any external dependency.  Mouse movement nudges the bands.
Item {
    id: root
    clip: true
    property bool motionEnabled: true
    property var colors: ["#ff5c7a", "#8a5cff", "#00ffd1"]
    property real speed: 0.2

    // Mouse parallax target
    property real mx: 0
    property real my: 0

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: {
            root.mx = (mouse.x / Math.max(width,1) - 0.5) * 2
            root.my = (mouse.y / Math.max(height,1) - 0.5) * 2
        }
    }

    // Layered rotating color bands
    Repeater {
        model: root.colors.length
        delegate: Rectangle {
            required property int index
            anchors.centerIn: parent
            width: parent.width * 1.6
            height: parent.height * 1.6
            rotation: index * 40
            opacity: 0.35
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: Util.withAlpha(root.colors[index], 0.0) }
                GradientStop { position: 0.5; color: Util.withAlpha(root.colors[index], 0.55) }
                GradientStop { position: 0.7; color: Util.withAlpha(root.colors[index], 0.0) }
                GradientStop { position: 1.0; color: "transparent" }
            }

            Behavior on rotation { NumberAnimation { duration: 100 } }

            // Slow rotation
            NumberAnimation on rotation {
                running: root.motionEnabled
                from: index * 40
                to: index * 40 + 360
                duration: 60000 / (index + 1)
                loops: Animation.Infinite
            }

            // Parallax offset
            x: root.mx * (12 + index * 6)
            y: root.my * (12 + index * 6)
            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }
    }

    // Secondary warp layer: scaled, counter-rotating bands
    Repeater {
        model: root.colors.length
        delegate: Rectangle {
            required property int index
            anchors.centerIn: parent
            width: parent.width * 1.2
            height: parent.height * 1.2
            rotation: -index * 60
            opacity: 0.22
            scale: 1.0 + 0.05 * Math.sin(Date.now() / 2000 + index)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.4; color: Util.withAlpha(root.colors[(index + 1) % root.colors.length], 0.4) }
                GradientStop { position: 0.6; color: Util.withAlpha(root.colors[(index + 1) % root.colors.length], 0.0) }
                GradientStop { position: 1.0; color: "transparent" }
            }

            NumberAnimation on rotation {
                running: root.motionEnabled
                from: -index * 60
                to: -index * 60 - 360
                duration: 45000 / (index + 1)
                loops: Animation.Infinite
            }
        }
    }

    // Soft vignette to keep content readable
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.6; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }
}
