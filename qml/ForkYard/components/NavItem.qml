import QtQuick
import QtQuick.Layouts
import "../util.js" as Util

// One row of the category navigation.
Rectangle {
    id: root

    property bool selected: false
    property string iconName: "cog"
    property string label: ""
    property int count: 0

    signal clicked()

    implicitHeight: 36
    property real tiltX: 0
    property real tiltY: 0
    property real maxTilt: 3
    property real clickScale: 1.0
    property real floatY: 0
    implicitWidth: parent ? parent.width : 200

    // The title is split into letters for the idle wave.
    readonly property var letterList: label.length > 0 ? label.split("") : []

    // The title drifts gently up and down.  The movement never stops
    // abruptly: both halves of the cycle use the same sine easing, so the
    // title turns around smoothly and the loop is invisible.
    SequentialAnimation {
        id: floatAnimation
        running: true
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "floatY"; from: -1.2; to: 1.2; duration: 2600; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "floatY"; from: 1.2; to: -1.2; duration: 2600; easing.type: Easing.InOutSine }
    }

    Timer {
        id: clickResetTimer
        interval: 150
        repeat: false
        onTriggered: {
            root.clickScale = 1.0
        }
    }

    readonly property bool isHovered: mouseArea.containsMouse && !mouseArea.pressed && enabled

    color: selected ? Util.withAlpha(Theme.color.accent, 0.18)
                    : (isHovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03))
    transform: [
        Scale { origin.x: root.width/2; origin.y: root.height/2; xScale: root.clickScale; yScale: root.clickScale },
        Rotation { origin.x: root.width/2; origin.y: root.height/2; axis { x: 1; y: 0; z: 0 } angle: root.tiltX },
        Rotation { origin.x: root.width/2; origin.y: root.height/2; axis { x: 0; y: 1; z: 0 } angle: root.tiltY }
    ]
    Behavior on tiltX { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on tiltY { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on clickScale { NumberAnimation { duration: 250; easing.type: Easing.OutBounce } }
    radius: Theme.radius.control
    border.width: 1
    border.color: selected ? Util.withAlpha(Theme.color.accent, 0.4) : (isHovered ? Util.withAlpha("#ffffff", 0.12) : "transparent")
    Behavior on color {
        ColorAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic }
    }

    // Active marker on the leading edge.
    Rectangle {
        width: 3
        height: 18
        radius: 1.5
        color: Theme.color.accent
        anchors.left: parent.left
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.selected ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: Theme.motion.base; easing.type: Easing.OutCubic }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space.lg
        anchors.rightMargin: Theme.space.lg
        spacing: Theme.space.lg

        IconGlyph {
            iconName: root.iconName
            glyphSize: 16
            tint: root.selected ? Theme.color.accent
                                : (root.isHovered ? Theme.color.text : Theme.color.textDim)
            Behavior on tint {
                ColorAnimation { duration: Theme.motion.fast }
            }
        }

        // The title is built letter by letter.  Every letter drifts on
        // its own with a small phase offset, so the word breathes
        // instead of sitting still.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Row {
                id: letters
                anchors.verticalCenter: parent.verticalCenter
                // A hair of space between the letters, so two of them can
                // never melt into one while they drift.
                spacing: 0.6
                scale: Math.min(1, parent.width / Math.max(1, letters.width))
                transformOrigin: Item.Left

                Repeater {
                    model: root.letterList

                    Text {
                        required property string modelData
                        required property int index
                        property real phase: 0

                        text: modelData
                        color: root.selected ? Theme.color.text
                                            : (root.isHovered ? Theme.color.text : Theme.color.textDim)
                        font.family: Theme.font.family.ui
                        font.pixelSize: Theme.font.size.bodySmall
                        font.weight: root.selected ? Font.DemiBold : Font.Normal
                        Behavior on color {
                            ColorAnimation { duration: Theme.motion.fast }
                        }

                        // The idle float of a single letter.
                        transform: Translate {
                            y: Math.sin(phase) * (root.isHovered ? 2.4 : 1.4)
                        }

                        // Every letter runs at the same speed but starts at
                        // another phase, so the wave travels through the
                        // word without ever stopping.
                        NumberAnimation on phase {
                            running: true
                            from: index * 0.46
                            to: index * 0.46 + Math.PI * 2
                            duration: 5200
                            loops: Animation.Infinite
                        }
                    }
                }
            }
        }

        Text {
            text: root.count
            color: root.selected ? Util.withAlpha(Theme.color.accent, 0.9) : Theme.color.textFaint
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.micro
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Keyboard focus ring.
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
        onPositionChanged: {
            var cx = mouse.x - width / 2
            var cy = mouse.y - height / 2
            root.tiltY = -(cx / Math.max(width,1)) * root.maxTilt
            root.tiltX = (cy / Math.max(height,1)) * root.maxTilt
        }
        onExited: { root.tiltX = 0; root.tiltY = 0 }
        onClicked: {
            root.clickScale = 0.85
            clickResetTimer.start()
            root.clicked()
        }
    }

    Keys.enabled: root.enabled
    Keys.onPressed: {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.clicked()
    }
}
