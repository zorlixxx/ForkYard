import QtQuick
import "../util.js" as Util

// A glass panel, ported from the React Bits "Glass Surface" component.
//
// The original bends the content behind it with an SVG displacement map
// and splits it into colour channels for the chromatic fringe.  Where
// that is not possible it falls back to a frosted surface: a translucent
// body, a one pixel light border, an inner bevel and a specular
// highlight that follows the pointer.
//
// This port keeps exactly that fallback treatment:
//
//   - a translucent body that lets the background shine through,
//   - a light border with a brighter edge on top and a dim one below,
//   - the inner bevel of the original, as two inset lines,
//   - a specular highlight that travels with the pointer,
//   - a fine grain that keeps the wide gradients from banding.
//
// Nothing is rotated or scaled: the panel fills its cell and the grid
// clips it, so a transform would cut the corners off.
Item {
    id: root
    objectName: "glassPanel"

    property real radius: Theme.radius.card
    property color tint: Theme.color.accent
    property bool hovered: false
    property bool highlight: true
    property bool shadow: true
    property bool grain: true
    // An opaque base under the glass.  Cards use it so the text stays
    // readable over the moving background.
    property color baseColor: "transparent"
    // The border glow lights up while the panel is hovered.
    property bool borderGlow: true
    // The size of the highlight that follows the pointer.  Small panels
    // take a big one, a full window would drown in it.
    property real specularSize: 0.85
    property real specularOpacity: 0.4

    // --------------------------------------------------------- border glow
    // The light of the frame follows the pointer, exactly like the
    // Border Glow component of React Bits.
    BorderGlow {
        anchors.fill: parent
        radius: root.radius
        intensity: root.hovered ? 0.55 : 0.0
        coneSpread: 44
        sparks: 12
        interactive: true
        alwaysOn: false
        animated: false
    }

    // ------------------------------------------------------------- shadow
    // It only reaches downwards, the cell of the grid has no room above.
    Rectangle {
        visible: root.shadow
        anchors.fill: parent
        anchors.bottomMargin: -6
        radius: root.radius
        color: Qt.rgba(0, 0, 0, 0.26)
        opacity: root.shadow ? (root.hovered ? 0.42 : 0.26) : 0.0
        z: -1
        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
    }

    // -------------------------------------------------------- glass body
    Rectangle {
        id: base
        anchors.fill: parent
        radius: root.radius
        color: root.baseColor
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        clip: true

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Util.withAlpha("#ffffff", root.hovered ? 0.12 : 0.085) }
            GradientStop { position: 0.55; color: Util.withAlpha("#ffffff", root.hovered ? 0.05 : 0.035) }
            GradientStop { position: 1.0; color: Util.withAlpha(root.tint, root.hovered ? 0.085 : 0.05) }
        }

        // ------------------------------------------------------- the grain
        Image {
            anchors.fill: parent
            source: Assets.ui["glass-grain.png"]
            fillMode: Image.Tile
            opacity: root.grain ? 0.30 : 0.0
            visible: root.grain
        }

        // ------------------------------------------ the specular highlight
        // The light of the panel follows the pointer.
        Image {
            id: specular
            source: Assets.ui["glow-violet.png"]
            width: Math.max(1, root.width * root.specularSize)
            height: width
            x: (pointerArea.hovered ? pointerArea.point.position.x : root.width / 2) - width / 2
            y: (pointerArea.hovered ? pointerArea.point.position.y : root.height / 2) - height / 2
            opacity: pointerArea.hovered ? root.specularOpacity : 0.0
            smooth: true
            Behavior on opacity { NumberAnimation { duration: Theme.motion.base } }
        }
    }

    // ------------------------------------------------------------- border
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: root.hovered ? Util.withAlpha(root.tint, 0.5)
                                   : Util.withAlpha("#ffffff", 0.15)
        Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }
    }

    // ------------------------------------------------- the inner bevel
    // The original gets these two lines from the inset box shadows.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        color: Util.withAlpha("#ffffff", root.hovered ? 0.30 : 0.20)
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        color: Util.withAlpha("#ffffff", 0.08)
    }

    // A cold rim on the right, the way light bends around the glass.
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 1
        width: 1
        color: Util.withAlpha(root.tint, root.hovered ? 0.28 : 0.14)
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
    }

    HoverHandler {
        id: pointerArea
    }
}
