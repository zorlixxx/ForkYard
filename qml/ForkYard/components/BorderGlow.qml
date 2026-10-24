import QtQuick
import "../util.js" as Util

// The border glow, ported from the React Bits "Border Glow" component.
//
// The original lights a cone of a conic gradient that follows the cursor
// around the frame of a card, lets a mesh gradient bleed into the edges
// and adds an outer halo.  It can also play a one shot sweep when it
// appears.
//
// Here the cone becomes a ring of small lights around the frame: the
// ones close to the cursor angle shine, the rest stay dark, so the beam
// travels around the border exactly like the original.  On top of that
// the component can sweep once around the frame and then keep a slow
// light running along it.
Item {
    id: root
    objectName: "borderGlow"

    property color glowColor: Theme.color.accent
    property real intensity: 0.75
    // The width of the lit cone, in degrees.
    property real coneSpread: 46
    // How many lights sit around the frame.
    property int sparks: 14
    // The size of a single light.  Small values read as a filament that
    // glides along the frame, big ones as a soft cloud.
    property real sparkSize: 84
    property real radius: Theme.radius.dialog
    // The beam follows the pointer.
    property bool interactive: true
    // A slow light keeps running around the frame.
    property bool alwaysOn: true
    // The one shot sweep that plays when the panel appears.
    property bool animated: true
    property int sweepDuration: 2200
    property bool running: true

    property real pointerAngle: 90
    property real idleAngle: 90
    property real sweepAngle: 110
    property real sweepWeight: 0

    readonly property real beamAngle: sweepWeight > 0 ? sweepAngle
                                       : (interactive ? pointerAngle : idleAngle)
    readonly property real beamStrength: sweepWeight > 0 ? sweepWeight : 1.0

    // The frame of the panel, as a rounded rectangle.
    readonly property real panelWidth: Math.max(1, width)
    readonly property real panelHeight: Math.max(1, height)
    readonly property real corner: Math.max(0, Math.min(radius, Math.min(panelWidth, panelHeight) / 2))
    // The magic constant that turns a cubic bezier into a quarter circle.
    readonly property real arc: corner * 0.5523

    // How bright a light at that angle shines.
    function sparkOpacity(angle) {
        if (!root.running || root.intensity <= 0)
            return 0
        var diff = Math.abs(((angle - root.beamAngle + 540) % 360) - 180)
        var spread = Math.max(6, root.coneSpread)
        if (diff >= spread)
            return 0
        var falloff = 1 - diff / spread
        return root.intensity * root.beamStrength * falloff * falloff
    }

    // The light that runs slowly around the frame.
    NumberAnimation on idleAngle {
        running: root.alwaysOn && root.running
        from: 0
        to: 360
        duration: 16000
        loops: Animation.Infinite
        easing.type: Easing.InOutSine
    }

    // The one shot sweep of the original: the light runs once around the
    // frame and fades away again.
    SequentialAnimation {
        id: sweepAnimation
        NumberAnimation {
            target: root
            property: "sweepAngle"
            from: 110
            to: 465
            duration: root.sweepDuration
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: root
            property: "sweepWeight"
            from: 1
            to: 0
            duration: 700
            easing.type: Easing.InCubic
        }
    }

    function triggerSweep() {
        if (!root.animated)
            return
        root.sweepAngle = 110
        root.sweepWeight = 1
        sweepAnimation.restart()
    }

    Component.onCompleted: triggerSweep()

    // The beam leans towards the pointer.
    HoverHandler {
        id: pointer
        onPointChanged: {
            if (!root.interactive)
                return
            var dx = pointer.point.position.x - root.width / 2
            var dy = pointer.point.position.y - root.height / 2
            if (dx === 0 && dy === 0)
                return
            var degrees = Math.atan2(dy, dx) * (180 / Math.PI) + 90
            if (degrees < 0)
                degrees += 360
            root.pointerAngle = degrees
        }
    }

    Behavior on pointerAngle {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // ------------------------------------------------------ the light ring
    PathView {
        id: ring
        anchors.fill: parent
        model: root.sparks
        visible: root.running && root.intensity > 0
        clip: false

        path: Path {
            startX: root.corner
            startY: 0

            PathLine { x: root.panelWidth - root.corner; y: 0 }
            PathCubic {
                x: root.panelWidth
                y: root.corner
                control1X: root.panelWidth - root.corner + root.arc
                control1Y: 0
                control2X: root.panelWidth
                control2Y: root.corner - root.arc
            }
            PathLine { x: root.panelWidth; y: root.panelHeight - root.corner }
            PathCubic {
                x: root.panelWidth - root.corner
                y: root.panelHeight
                control1X: root.panelWidth
                control1Y: root.panelHeight - root.corner + root.arc
                control2X: root.panelWidth - root.corner + root.arc
                control2Y: root.panelHeight
            }
            PathLine { x: root.corner; y: root.panelHeight }
            PathCubic {
                x: 0
                y: root.panelHeight - root.corner
                control1X: root.corner - root.arc
                control1Y: root.panelHeight
                control2X: 0
                control2Y: root.panelHeight - root.corner + root.arc
            }
            PathLine { x: 0; y: root.corner }
            PathCubic {
                x: root.corner
                y: 0
                control1X: 0
                control1Y: root.corner - root.arc
                control2X: root.corner - root.arc
                control2Y: 0
            }
        }

        delegate: Item {
            required property int index
            id: spark

            // The angle of this light, seen from the centre of the panel.
            readonly property real angle: {
                var px = x + width / 2 - root.width / 2
                var py = y + height / 2 - root.height / 2
                if (px === 0 && py === 0)
                    return 90
                var degrees = Math.atan2(py, px) * (180 / Math.PI) + 90
                if (degrees < 0)
                    degrees += 360
                return degrees
            }

            width: 1
            height: 1

            Image {
                anchors.centerIn: parent
                width: root.sparkSize
                height: root.sparkSize
                source: Assets.ui["glow-violet.png"]
                smooth: true
                opacity: root.sparkOpacity(spark.angle)
                Behavior on opacity {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
