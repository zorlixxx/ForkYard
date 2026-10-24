import QtQuick
import "../util.js" as Util

// Minimal glass cursor: uses the downloaded Windows cursor (Cursor.cur),
// drawn as an image that follows the pointer on a damped spring.
// No pill, no trails, no bloom -- just the cursor image on glass.
Item {
    id: root
    objectName: "customCursor"
    clip: true

    property string name: "ForkYard"
    property color accent: Theme.color.accent
    property real size: 32
    property real restTilt: -12
    property bool directionAwareTilt: true

    property real stiffness: 460
    property real damping: 34
    property real mass: 0.5

    property real targetX: 0
    property real targetY: 0
    property real arrowX: 0
    property real arrowY: 0
    property real arrowVX: 0
    property real arrowVY: 0

    property real tilt: restTilt
    readonly property real hoverScale: Cursor.interactive ? 1.14 : (Cursor.inside ? 1.04 : 1.0)
    readonly property bool shown: Cursor.inside && !Cursor.textMode

    onTargetXChanged: {
        if (arrowX === 0 && arrowY === 0) {
            arrowX = targetX
            arrowY = targetY
        }
    }

    function step(dt) {
        var ax = (targetX - arrowX) * stiffness / mass
        var ay = (targetY - arrowY) * stiffness / mass
        arrowVX += (ax - damping * arrowVX / mass) * dt
        arrowVY += (ay - damping * arrowVY / mass) * dt
        arrowX += arrowVX * dt
        arrowY += arrowVY * dt

        if (directionAwareTilt) {
            var speed = Math.sqrt(arrowVX * arrowVX + arrowVY * arrowVY)
            if (speed > 14) {
                var wanted = Math.atan2(arrowVY, arrowVX) * 180 / Math.PI + 90
                var diff = ((wanted - tilt + 540) % 360) - 180
                tilt += diff * Math.min(1, dt * 10)
            } else {
                tilt += (restTilt - tilt) * Math.min(1, dt * 6)
            }
        } else {
            tilt += (restTilt - tilt) * Math.min(1, dt * 7)
        }
    }

    FrameAnimation {
        running: true
        onTriggered: {
            var now = Date.now()
            var dt = root.lastStep > 0 ? Math.min(0.05, (now - root.lastStep) / 1000) : 0.016
            root.lastStep = now
            root.step(dt)
        }
    }

    property real lastStep: 0

    Connections {
        target: Cursor
        function onXChanged() { root.targetX = Cursor.x }
        function onYChanged() { root.targetY = Cursor.y }
    }

    // ---------------------------------------------------------------- cursor
    // The downloaded Windows cursor image, centred on the pointer.
    Image {
        id: cursorImg
        source: Assets.cursor ? Assets.cursor : ""
        width: root.size
        height: root.size
        visible: root.shown
        opacity: root.shown ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        smooth: true
        fillMode: Image.PreserveAspectFit

        x: root.arrowX - root.size / 2
        y: root.arrowY - root.size / 2

        // Transparent to mouse input: the custom cursor must never steal
        // hover/click events from the interface underneath.
        MouseArea {
            anchors.fill: parent
            enabled: false
        }

        transformOrigin: Item.Center
        transform: [
            Scale {
                origin.x: width / 2
                origin.y: height / 2
                xScale: (Cursor.pressed ? 0.84 : 1.0) * root.hoverScale
                yScale: (Cursor.pressed ? 0.84 : 1.0) * root.hoverScale
                Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            },
            Rotation {
                origin.x: width / 2
                origin.y: height / 2
                angle: root.tilt
                Behavior on angle { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            }
        ]
    }
}
