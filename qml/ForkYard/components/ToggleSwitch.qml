import QtQuick
import "../util.js" as Util

// A compact on/off switch with a clear on and off state.
Item {
    id: root

    property bool checked: false
    property color onColor: Theme.color.accent
    property color offColor: Theme.color.surfaceHi

    signal toggled(bool value)

    implicitWidth: 38
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? root.onColor : root.offColor
        border.width: 1
        border.color: root.checked ? Util.withAlpha(root.onColor, 0.9) : Theme.color.borderHi

        Behavior on color {
            ColorAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic }
        }

        Rectangle {
            width: track.height - 6
            height: width
            radius: width / 2
            y: 3
            x: root.checked ? track.width - width - 3 : 3
            color: root.checked ? Theme.color.textOnAccent : Theme.color.textFaint

            Behavior on x {
                NumberAnimation { duration: Theme.motion.base; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.motion.fast }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
