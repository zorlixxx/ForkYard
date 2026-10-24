import QtQuick
import "../util.js" as Util

// A lightweight cursor motion trail.
//
// Records recent cursor positions and paints them as small, fading
// luminous dots.  The trail is purely decorative: it never captures
// clicks or hover, so every button and link underneath stays fully
// interactive.  Cursor position is polled from the global cursor so no
// full-screen MouseArea is needed (which would otherwise steal hover
// events from the real controls).
Item {
    id: root

    enabled: false   // never intercept input

    property bool motionEnabled: root.active
    property int maxAge: 600
    property int sampleInterval: 22
    property real maxOpacity: 0.6
    property int pointSize: 14

    property var points: []

    Timer {
        id: sampler
        interval: root.sampleInterval
        running: root.motionEnabled
        repeat: true
        onTriggered: {
            var g = controller.cursorGlobal()
            if (!g)
                return
            var local = root.mapFromGlobal(g.x, g.y)
            var last = root.points.length > 0 ? root.points[root.points.length - 1] : null
            if (last && Math.abs(last.x - local.x) < 1 && Math.abs(last.y - local.y) < 1)
                return
            var now = Date.now()
            root.points.push({ x: local.x, y: local.y, t: now })
            while (root.points.length > 0 &&
                   now - root.points[0].t > root.maxAge)
                root.points.shift()
            root.points = root.points.slice()
        }
    }

    Repeater {
        model: root.points
        delegate: Rectangle {
            width: root.pointSize
            height: root.pointSize
            radius: width / 2
            color: Theme.color.accent
            x: modelData.x - width / 2
            y: modelData.y - height / 2
            opacity: root.maxOpacity

            Behavior on opacity {
                NumberAnimation { duration: root.maxAge; easing.type: Easing.OutCubic }
            }

            Component.onCompleted: opacity = 0

            // Outer glow
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 2.6
                height: width
                radius: width / 2
                color: Util.withAlpha(Theme.color.accent, 0.18)
                z: -1
            }
        }
    }
}
