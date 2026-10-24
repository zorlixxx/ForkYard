import QtQuick
import "../util.js" as Util

// The liquid chrome background.
//
// The original React Bits component paints the surface with a WebGL
// shader: a fluid simulation that feeds a chrome pass with a small
// studio.  This port rebuilds the same flowing metal with plain QML
// primitives, so it runs on every graphics backend Qt supports:
//
//   - a row of polished ridges that travel sideways like a wave,
//   - a second, slower set of ridges for depth,
//   - a specular sweep that crosses the surface,
//   - a studio glow that follows the pointer.
Item {
    id: root
    objectName: "liquidChrome"

    property color tintColor: "#A855F7"
    property real speed: 0.34
    property real amplitude: 0.3
    property real frequencyX: 6.1
    property real frequencyY: 4.5
    property real detail: 4
    property real thickness: 0.5
    property real depth: 1.1
    property real roughness: 0.5
    property real exposure: 0.7
    property real tilt: 0.75
    property bool motionEnabled: true

    // The pointer of the window, in normalised coordinates (-1 to 1).
    property real pointerX: 0
    property real pointerY: 0
    property bool pointerInside: false
    property real rippleStrength: 1.0
    property real rippleSize: 1.3

    // The light of the studio leans towards the pointer.
    property real lightX: 0
    property real lightY: 0

    readonly property int barCount: Math.max(30, Math.round(width / 9))
    readonly property real spacing: width / Math.max(1, barCount)

    // A stable pseudo random number per ridge, so the pattern never
    // repeats itself and does not look like a screen door.
    function jitter(index) {
        var value = Math.sin(index * 12.9898 + 78.233) * 43758.5453
        return value - Math.floor(value)
    }

    Behavior on lightX {
        NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
    }
    Behavior on lightY {
        NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
    }

    onPointerXChanged: {
        if (pointerInside)
            lightX = pointerX * 0.35 * tilt
        else
            lightX = 0
    }
    onPointerYChanged: {
        if (pointerInside)
            lightY = -pointerY * 0.28 * tilt
        else
            lightY = 0
    }
    onPointerInsideChanged: {
        if (!pointerInside) {
            lightX = 0
            lightY = 0
        }
    }

    // ------------------------------------------------------------- surface
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#141026" }
            GradientStop { position: 0.5; color: "#0D0A18" }
            GradientStop { position: 1.0; color: "#07060D" }
        }
    }

    // --------------------------------------------------------- metal ridges
    Item {
        objectName: "decorative-ridges"
        id: ridges
        anchors.fill: parent
        clip: true
        opacity: root.exposure

        Repeater {
            model: root.barCount

            Rectangle {
                objectName: "decorative-ridge"
                required property int index
                property real phase: 0

                width: root.spacing * (1.4 + root.jitter(index) * 0.7)
                height: root.height * (1.5 + root.jitter(index + 31) * 0.35)
                x: index * root.spacing - width * 0.2
                y: root.height / 2 - height / 2 + Math.sin(phase) * (12 + root.amplitude * 30)
                rotation: -9 + root.lightX * 6 + (root.jitter(index + 7) - 0.5) * 5
                opacity: 0.35 + root.jitter(index + 13) * 0.35

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.34; color: Util.withAlpha(root.tintColor, 0.035) }
                    GradientStop { position: 0.48; color: Util.withAlpha("#ffffff", 0.055) }
                    GradientStop { position: 0.52; color: Util.withAlpha("#ffffff", 0.07) }
                    GradientStop { position: 0.66; color: Util.withAlpha(root.tintColor, 0.035) }
                    GradientStop { position: 1.0; color: "transparent" }
                }

                // Every ridge runs at the same speed but starts at another
                // phase, so the wave travels across the surface.
                NumberAnimation on phase {
                    running: root.motionEnabled
                    from: index * 0.22
                    to: index * 0.22 + Math.PI * 2
                    duration: 7200
                    loops: Animation.Infinite
                }
            }
        }
    }

    // A second, slower set of ridges for depth.
    Item {
        objectName: "decorative-deep-ridges"
        id: deepRidges
        anchors.fill: parent
        clip: true
        opacity: 0.28 * root.exposure
        rotation: 7

        Repeater {
            model: Math.round(root.barCount * 0.5)

            Rectangle {
                objectName: "decorative-ridge-deep"
                required property int index
                property real phase: 0

                width: root.spacing * 3.4
                height: root.height * 1.9
                x: index * root.spacing * 1.9 - width * 0.8
                y: root.height / 2 - height / 2 + Math.sin(phase) * 24
                rotation: 6 + (root.jitter(index + 5) - 0.5) * 6

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Util.withAlpha("#9FB4CC", 0.045) }
                    GradientStop { position: 1.0; color: "transparent" }
                }

                NumberAnimation on phase {
                    running: root.motionEnabled
                    from: index * 0.31
                    to: index * 0.31 + Math.PI * 2
                    duration: 11000
                    loops: Animation.Infinite
                }
            }
        }
    }

    // ------------------------------------------------------- studio lights
    // The key light of the studio, leaning with the pointer.
    Image {
        objectName: "decorative-key-light"
        id: keyLight
        source: Assets.ui["glow-violet.png"]
        width: Math.max(1, root.width * 1.25)
        height: width
        x: root.width / 2 - width / 2 + root.lightX * root.width * 0.6
        y: root.height / 2 - height / 2 + root.lightY * root.height * 0.6
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: 0.55 * root.exposure
    }

    // A cold rim light on the other side keeps the metal from looking flat.
    Image {
        objectName: "decorative-rim-light"
        width: Math.max(1, root.width * 1.0)
        height: width
        x: root.width * 0.74 - width / 2
        y: root.height * 0.22 - height / 2
        source: Assets.ui["glow-steel.png"]
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: 0.5 * root.exposure
    }

    // -------------------------------------------------------- specular sweep
    Rectangle {
        objectName: "decorative-sweep"
        id: sweep
        width: root.width * 0.42
        height: root.height * 2.2
        x: -root.width * 0.5
        y: root.height / 2 - height / 2
        rotation: -22
        opacity: 0.7 * root.exposure

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.42; color: Util.withAlpha("#ffffff", 0.05) }
            GradientStop { position: 0.5; color: Util.withAlpha("#ffffff", 0.09) }
            GradientStop { position: 0.58; color: Util.withAlpha("#ffffff", 0.05) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        NumberAnimation on x {
            running: root.motionEnabled
            from: -root.width * 0.5
            to: root.width
            duration: 11000
            loops: Animation.Infinite
        }
    }

    // ------------------------------------------------------------- vignette
    // The ridges fade out towards the bottom, so the empty part of the
    // window stays calm and the pattern never reads as a screen door.
    Rectangle {
        anchors.fill: parent
        opacity: 0.92
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#000000" }
            GradientStop { position: 0.28; color: "transparent" }
            GradientStop { position: 0.55; color: "#050409" }
            GradientStop { position: 1.0; color: "#080610" }
        }
    }
}
