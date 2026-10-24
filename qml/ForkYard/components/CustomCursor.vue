import QtQuick
import QtQuick Shapes
import "../util.js" as Util

// The custom cursor, ported from the React Bits "User Cursor".
Item {
    id: root
    objectName: "customCursor"

    property string name: "ForkYard"
    property color accent: Theme.color.accent
    property color textColor: "#FFFFFF"
    property real size: 22
    property real restTilt: -14
    property bool directionAwareTilt: true
    property real labelTiltStrength: 9
    property real pressScale: 0.9
    property bool showLabel: true

    property real stiffness: 380
    property real damping: 32
    property real mass: 0.6
    property real labelStiffness: 210
    property real labelDamping: 26
    property real labelMass: 0.7

    property real targetX: 0
    property real targetY: 0
    property real arrowX: 0
    property real arrowY: 0
    property real arrowVX: 0
    property real arrowVY: 0
    property real labelX: 0
    property real labelY: 0
    property real labelVX: 0
    property real labelVY: 0

    property real tilt: restTilt
    property real labelTilt: 0
    readonly property real hoverScale: Cursor.interactive ? 1.14 : 1.0
    readonly property bool shown: Cursor.inside && !Cursor.textMode

    onTargetXChanged: {
        if (arrowX === 0 && arrowY === 0) {
            arrowX = targetX
            arrowY = targetY
            labelX = targetX
            labelY = targetY
        }
    }

    function step(dt) {
        var ax = (targetX - arrowX) * stiffness / mass
        var ay = (targetY - arrowY) * stiffness / mass
        arrowVX += (ax - damping * arrowVX / mass) * dt
        arrowVY += (ay - damping * arrowVY / mass) * dt
        arrowX += arrowVX * dt
        arrowY += arrowVY * dt

        var lx = (targetX - labelX) * labelStiffness / labelMass
        var ly = (targetY - labelY) * labelStiffness / labelMass
        labelVX += (lx - labelDamping * labelVX / labelMass) * dt
        labelVY += (ly - labelDamping * labelVY / labelMass) * dt
        labelX += labelVX * dt
        labelY += labelVY * dt

        if (directionAwareTilt) {
            var speed = Math.sqrt(arrowVX * arrowVX + arrowVY * arrowVY)
            if (speed > 12) {
                var wanted = Math.atan2(arrowVY, arrowVX) * 180 / Math.PI + 90
                var diff = ((wanted - tilt + 540) % 360) - 180
                tilt += diff * Math.min(1, dt * 9)
            } else {
                tilt += (restTilt - tilt) * Math.min(1, dt * 5)
            }
        } else {
            tilt += (restTilt - tilt) * Math.min(1, dt * 8)
        }

        var rock = Math.max(-1, Math.min(1, labelVX / 900))
        labelTilt += (rock * labelTiltStrength - labelTilt) * Math.min(1, dt * 10)
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

    Shape {
        id: arrow
        x: root.arrowX - root.size * 0.32
        y: root.arrowY - root.size * 0.32
        width: root.size * 1.6
        height: root.size * 1.6
        visible: root.shown
        opacity: root.shown ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        transform: [
            Scale {
                origin.x: root.size * 0.32
                origin.y: root.size * 0.32
                xScale: (Cursor.pressed ? root.pressScale : 1.0) * root.hoverScale
                yScale: (Cursor.pressed ? root.pressScale : 1.0) * root.hoverScale
                Behavior on xScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on yScale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            },
            Rotation {
                origin.x: root.size * 0.32
                origin.y: root.size * 0.32
                angle: root.tilt
                Behavior on angle { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            }
        ]

        ShapePath {
            startX: root.size * 0.32
            startY: root.size * 0.32
            PathLine { x: root.size * 0.32; y: root.size * 1.26 }
            PathLine { x: root.size * 0.66; y: root.size * 0.84 }
            PathLine { x: root.size * 0.88; y: root.size * 1.26 }
            PathLine { x: root.size * 1.06; y: root.size * 1.12 }
            PathLine { x: root.size * 0.84; y: root.size * 0.72 }
            PathLine { x: root.size * 1.22; y: root.size * 0.72 }
            PathLine { x: root.size * 0.32; y: root.size * 0.32 }
            fillColor: root.accent
            strokeColor: Util.withAlpha("#0A0811", 0.55)
            strokeWidth: 1
        }
    }

    Rectangle {
        id: pill
        visible: root.shown && root.showLabel
        opacity: root.shown && root.showLabel ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        x: root.labelX + root.size * 0.92
        y: root.labelY + root.size * 0.2 + 6
        width: pillRow.implicitWidth + Theme.space.lg * 2
        height: 26
        radius: height / 2
        color: root.accent

        transform: Rotation {
            origin.x: width / 2
            origin.y: height / 2
            angle: root.labelTilt
            Behavior on angle { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: Theme.space.sm

            IconGlyph {
                anchors.verticalCenter: parent.verticalCenter
                iconName: "workflow"
                glyphSize: 12
                tint: root.textColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.name
                color: root.textColor
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.micro
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
            }
        }
    }
}