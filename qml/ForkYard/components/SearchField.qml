import QtQuick
import QtQuick.Controls.Basic
import "../util.js" as Util

// The global search box.
//
// It rests as a single magnifier icon in the header.  When the pointer
// comes close the box unfolds sideways into the real search field, and it
// stays open while it holds the focus or while it carries a query.
//
// The search covers names, descriptions, tags and the category of every
// entry, not only the category headings.
Item {
    id: root
    objectName: "searchBox"

    property bool expanded: false
    property string glyph: "search"
    property int collapsedWidth: 36
    property int expandedWidth: 360
    property alias text: field.text
    // Set as soon as the user opens the box on purpose.
    property bool engaged: false

    signal searchChanged(string text)

    implicitHeight: 36
    implicitWidth: expanded ? expandedWidth : collapsedWidth

    // The box opens for the pointer, for the keyboard and for a query.
    readonly property bool wantsExpanded: hoverHandler.hovered
                                         || root.engaged
                                         || field.text.length > 0

    onWantsExpandedChanged: root.expanded = root.wantsExpanded

    function clear() {
        field.clear()
        field.forceActiveFocus()
    }

    // -------------------------------------------------------------- surface
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radius.control
        color: Theme.color.bgSoft
        opacity: root.expanded ? 1.0 : 0.55
        border.width: 1
        border.color: field.activeFocus ? Theme.color.accent
                                       : (root.expanded ? Theme.color.borderHi : Theme.color.border)
        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
        Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }
    }

    // A warm halo that appears while the magnifier is hovered.
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.control
        color: "transparent"
        border.width: 1
        border.color: Util.withAlpha(Theme.color.accent, 0.45)
        opacity: root.expanded ? 0.0 : (hoverHandler.hovered ? 1.0 : 0.0)
        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
    }

    // -------------------------------------------------------------- magnifier
    IconGlyph {
        id: glyphIcon
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        iconName: root.glyph
        glyphSize: 15
        tint: field.activeFocus ? Theme.color.accent
              : (root.expanded ? Theme.color.accent : Theme.color.textFaint)
        Behavior on tint { ColorAnimation { duration: Theme.motion.fast } }
    }

    // ------------------------------------------------------------ the field
    TextField {
        id: field
        objectName: "searchField"

        anchors.fill: parent
        leftPadding: 32
        rightPadding: 34
        topPadding: 0
        bottomPadding: 0

        placeholderText: "Search tweaks, tools and categories"
        placeholderTextColor: Theme.color.textFaint
        color: Theme.color.text
        selectionColor: Util.withAlpha(Theme.color.accent, 0.35)
        selectedTextColor: Theme.color.text
        font.family: Theme.font.family.ui
        font.pixelSize: Theme.font.size.bodySmall
        verticalAlignment: TextInput.AlignVCenter
        background: Item {
        }

        opacity: root.expanded ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        onTextChanged: {
            controller.playSound("writting-sfx")
            root.searchChanged(text)
        }

        // The text field grabs the keyboard focus when the window opens.
        // That must not unfold the box, only a real interaction does.
        onActiveFocusChanged: {
            if (!field.activeFocus && field.text.length === 0)
                root.engaged = false
        }

        Keys.onEscapePressed: {
            if (field.text.length > 0)
                field.clear()
            else
                field.focus = false
        }
    }

    IconButton {
        id: clearButton
        visible: field.text.length > 0 && root.expanded
        iconName: "x"
        buttonSize: 20
        quiet: true
        tint: Theme.color.textFaint
        hoverTint: Theme.color.text
        anchors.right: parent.right
        anchors.rightMargin: Theme.space.md
        anchors.verticalCenter: parent.verticalCenter
        onClicked: {
            field.clear()
            field.forceActiveFocus()
        }
    }

    // Clicking the collapsed magnifier opens the field and puts the
    // cursor into it.  While the field is open it handles the clicks
    // itself.
    MouseArea {
        anchors.fill: parent
        enabled: !root.expanded
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.engaged = true
            field.forceActiveFocus()
        }
    }

    HoverHandler {
        id: hoverHandler
    }
}
