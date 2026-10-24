import QtQuick
import QtQuick.Effects

// A monochrome interface glyph that can be tinted at runtime.
Item {
    id: root

    property string iconName: ""
    property color tint: "#ffffff"
    property real glyphSize: 16

    implicitWidth: glyphSize
    implicitHeight: glyphSize

    Image {
        id: mask
        anchors.fill: parent
        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: root.iconName ? (Assets.icons[root.iconName] || Assets.icons["cog"]) : ""
    }

    MultiEffect {
        anchors.fill: parent
        source: mask
        colorization: 1.0
        colorizationColor: root.tint
    }
}
