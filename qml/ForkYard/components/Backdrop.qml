import QtQuick
import "../util.js" as Util

// Aurora / Silk style animated backdrop inspired by reactbits.dev.
//
// Multiple soft, flowing color bands drift across a deep base and lean
// toward the cursor.  The motion is slow and calm so the interface stays
// readable and premium.
Item {
    id: root
    property bool motionEnabled: root.active
    clip: true

    // Mouse parallax target
    property real mx: 0.5
    property real my: 0.5

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: {
            root.mx = mouse.x / Math.max(width, 1)
            root.my = mouse.y / Math.max(height, 1)
        }
    }

    // Deep base
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#08060F" }
            GradientStop { position: 0.5; color: "#0C0917" }
            GradientStop { position: 1.0; color: "#05040A" }
        }
    }

    // Aurora band 1 (warm)
    Rectangle {
        id: b1
        width: parent.width * 1.6
        height: parent.height * 0.7
        opacity: 0.20
        rotation: -15
        x: (root.mx - 0.5) * 40 - parent.width * 0.3
        y: (root.my - 0.5) * 30 - parent.height * 0.1
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.25; color: Util.withAlpha(Theme.color.accent, 0.15) }
            GradientStop { position: 0.5; color: Util.withAlpha(Theme.color.accent, 0.55) }
            GradientStop { position: 0.75; color: Util.withAlpha(Theme.color.accent, 0.2) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        Behavior on x { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }

        SequentialAnimation on rotation {
            running: root.motionEnabled
            loops: Animation.Infinite
            NumberAnimation { from: -15; to: -10; duration: 22000; easing.type: Easing.InOutSine }
            NumberAnimation { from: -10; to: -15; duration: 22000; easing.type: Easing.InOutSine }
        }
    }

    // Aurora band 2 (cool blue)
    Rectangle {
        id: b2
        width: parent.width * 1.7
        height: parent.height * 0.6
        opacity: 0.14
        rotation: 10
        x: (root.mx - 0.5) * -30 + parent.width * 0.05
        y: (root.my - 0.5) * -25 + parent.height * 0.35
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: Util.withAlpha("#4a9eff", 0.12) }
            GradientStop { position: 0.5; color: Util.withAlpha("#4a9eff", 0.45) }
            GradientStop { position: 0.7; color: Util.withAlpha("#4a9eff", 0.15) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        Behavior on x { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }

        SequentialAnimation on rotation {
            running: root.motionEnabled
            loops: Animation.Infinite
            NumberAnimation { from: 10; to: 14; duration: 28000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 14; to: 10; duration: 28000; easing.type: Easing.InOutSine }
        }
    }

    // Aurora band 3 (purple)
    Rectangle {
        id: b3
        width: parent.width * 1.5
        height: parent.height * 0.5
        opacity: 0.12
        rotation: -6
        x: (root.mx - 0.5) * 20 + parent.width * 0.4
        y: (root.my - 0.5) * 20 + parent.height * 0.6
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: Util.withAlpha("#8a5cff", 0.1) }
            GradientStop { position: 0.5; color: Util.withAlpha("#8a5cff", 0.4) }
            GradientStop { position: 0.7; color: Util.withAlpha("#8a5cff", 0.12) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        Behavior on x { NumberAnimation { duration: 1600; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 1600; easing.type: Easing.OutCubic } }

        SequentialAnimation on rotation {
            running: root.motionEnabled
            loops: Animation.Infinite
            NumberAnimation { from: -6; to: -2; duration: 32000; easing.type: Easing.InOutSine }
            NumberAnimation { from: -2; to: -6; duration: 32000; easing.type: Easing.InOutSine }
        }
    }

    // Vignette
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: "transparent" }
            GradientStop { position: 0.85; color: "#000000" }
            GradientStop { position: 1.0; color: "#06050B" }
        }
        opacity: 0.55
    }
}
