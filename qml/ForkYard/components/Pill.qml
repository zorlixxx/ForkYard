import QtQuick
import "../util.js" as Util

// A compact inline badge: optional glyph plus a short label.
Item {
    id: root

    property string text: ""
    property string iconName: ""
    property color tint: Theme.color.textDim
    property bool uppercase: false
    property bool filled: false

    implicitHeight: 21
    implicitWidth: row.implicitWidth + Theme.space.lg

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.pill
        color: root.filled ? root.tint : Util.withAlpha(root.tint, 0.13)
        border.width: 1
        border.color: root.filled ? Util.withAlpha(root.tint, 0.55) : Util.withAlpha(root.tint, 0.30)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space.xs + 1

        IconGlyph {
            visible: root.iconName !== ""
            iconName: root.iconName
            glyphSize: 11
            tint: root.filled ? Theme.color.bg : root.tint
        }

        Text {
            text: root.uppercase ? root.text.toUpperCase() : root.text
            color: root.filled ? Theme.color.bg : root.tint
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.micro
            font.weight: root.uppercase ? Font.DemiBold : Font.Medium
            font.letterSpacing: root.uppercase ? Theme.font.tracking.micro : 0
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
