import QtQuick
import QtQuick.Effects
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// The dialog shell of the application.
//
// Every confirmation, help panel and notice is rendered inside the main
// window with this component, so the application never opens a second
// top level window.  It provides the surface, the header, the body
// area, an optional footer and the enter/exit transitions.
//
// The frame of the dialog never moves: it is always centred in the
// window.  Only the panel travels.  It slides in from the top or from
// the bottom - the direction is picked at random for every opening - and
// it is sucked back out when it closes.
Popup {
    id: control
    objectName: "appDialog"

    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    // The title reveals itself letter by letter.  A confirmation turns
    // this off, there the wording has to be readable at once.
    property bool scrambleTitle: true
    property int panelWidth: 560
    property int panelMaxHeight: 640
    property color accentColor: Theme.color.accent

    property string primaryText: ""
    property string tertiaryText: ""
    property bool primaryEnabled: true
    property bool showCloseButton: true

    // -1 = the panel enters from the top, 1 = it enters from the bottom.
    property int slideDir: 1
    // Vertical offset of the panel while it travels.
    property real travel: 0
    // Scale of the panel, 0.92 while it enters and 1 when it rests.
    property real scaleFactor: 1.0

    default property alias body: bodyArea.data
    property alias footerExtra: footerExtraArea.data

    signal primaryClicked()
    signal tertiaryClicked()

    modal: true
    padding: 0
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    focus: true

    // The dialog is always centred in the window, whatever its size is.
    x: Math.round(((parent ? parent.width : 1440) - width) / 2)
    y: Math.round(((parent ? parent.height : 900) - height) / 2)
    width: implicitWidth
    height: implicitHeight

    Overlay.modal: Rectangle {
        color: Util.withAlpha(Theme.color.scrim, 0.62)
    }

    // The visible surface is part of the content item, so it travels
    // together with the text instead of staying behind in the frame.
    background: Item {
    }

    contentItem: Item {
        id: panel
        implicitWidth: control.panelWidth
        // The height is taken from the layout itself, so the header, the
        // body and the footer always fit inside the panel.
        implicitHeight: Math.min(Math.max(contentLayout.implicitHeight, 260),
                                  control.panelMaxHeight)

        transformOrigin: Item.Center
        transform: [
            Translate {
                id: panelShift
                x: 0
                y: control.travel
            },
            Scale {
                id: panelScale
                origin.x: panel.width / 2
                origin.y: panel.height / 2
                xScale: control.scaleFactor
                yScale: control.scaleFactor
            }
        ]

        // The border glow: a light glides along the frame of the panel
        // and leans towards the pointer.
        BorderGlow {
            id: glow
            anchors.fill: parent
            radius: Theme.radius.dialog
            intensity: 0.95
            coneSpread: 38
            sparks: 18
            sparkSize: 46
            interactive: true
            alwaysOn: true
            animated: true
        }

        // The solid base of the panel.
        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.dialog
            color: Qt.rgba(0.08, 0.10, 0.15, 0.96)
        }

        // A sheet of glass on top of it: the sheen, the grain and the
        // highlight that follows the pointer.
        GlassPanel {
            anchors.fill: parent
            radius: Theme.radius.dialog
            shadow: false
            borderGlow: false
            specularSize: 0.42
            specularOpacity: 0.18
        }

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            spacing: 0

            // ------------------------------------------------------ header
            Item {
                id: headerArea
                Layout.fillWidth: true
                Layout.preferredHeight: headerRow.implicitHeight + Theme.space.xl * 2

                RowLayout {
                    id: headerRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: Theme.space.xxl
                    anchors.rightMargin: Theme.space.xl
                    anchors.topMargin: Theme.space.xl
                    spacing: Theme.space.lg

                    Rectangle {
                        visible: control.glyph !== ""
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: Theme.radius.sm + 2
                        color: Util.withAlpha(control.accentColor, 0.14)
                        border.width: 1
                        border.color: Util.withAlpha(control.accentColor, 0.35)

                        IconGlyph {
                            anchors.centerIn: parent
                            iconName: control.glyph
                            glyphSize: 17
                            tint: control.accentColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        ScrambleText {
                            Layout.fillWidth: true
                            text: control.title
                            color: Theme.color.text
                            fontSize: Theme.font.size.dialogTitle
                            // Long names reveal faster, the scramble should
                            // never hold the reader for more than a moment.
                            speed: Math.max(8, Math.min(34, Math.round(420 / Math.max(1, control.title.length))))
                            centered: false
                            active: control.scrambleTitle
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: control.subtitle !== ""
                            text: control.subtitle
                            color: Theme.color.textFaint
                            font.family: Theme.font.family.ui
                            font.pixelSize: Theme.font.size.label
                            elide: Text.ElideRight
                        }
                    }

                    IconButton {
                        objectName: "dialogClose"
                        visible: control.showCloseButton
                        iconName: "x"
                        buttonSize: 28
                        quiet: true
                        tint: Theme.color.textFaint
                        hoverTint: Theme.color.text
                        onClicked: control.close()
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.color.border
                }
            }

            // ------------------------------------------------------- body
            Item {
                id: bodyArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                // The body never pushes the footer out of the panel: a
                // body that is taller than the panel scrolls instead.
                Layout.minimumHeight: Math.min(bodyArea.contentHeight, 320)

                // The body content decides how tall the panel has to be.
                // Every dialog puts its content into this item, so the
                // preferred height is taken from the first child.
                readonly property real contentHeight: {
                    var wanted = 0
                    for (var i = 0; i < children.length; ++i) {
                        var child = children[i]
                        var height = child.implicitHeight
                        if (!height || height <= 0)
                            height = child.height
                        if (height > wanted)
                            wanted = height
                    }
                    return wanted
                }

                implicitHeight: contentHeight
            }

            // ----------------------------------------------------- footer
            Item {
                id: footerArea
                visible: control.primaryText !== ""
                         || control.tertiaryText !== "" || footerExtraArea.children.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? footerRow.implicitHeight + Theme.space.xl * 2 : 0

                RowLayout {
                    id: footerRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: Theme.space.xxl
                    anchors.rightMargin: Theme.space.xxl
                    anchors.bottomMargin: Theme.space.xl
                    spacing: Theme.space.md

                    Item {
                        id: footerExtraArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    AppButton {
                        objectName: "dialogTertiary"
                        visible: control.tertiaryText !== ""
                        text: control.tertiaryText
                        variant: "ghost"
                        onClicked: control.tertiaryClicked()
                    }

                    AppButton {
                        id: primaryButton
                        objectName: "dialogPrimary"
                        visible: control.primaryText !== ""
                        text: control.primaryText
                        enabled: control.primaryEnabled
                        onClicked: control.primaryClicked()
                    }
                }
            }
        }
    }

    // The direction is picked before the panel is shown, so the very
    // first frame already starts at the right edge.
    onAboutToShow: {
        control.slideDir = Math.random() > 0.5 ? -1 : 1
        var distance = (control.height > 0 ? control.height : 400) + 48
        control.travel = control.slideDir * distance
        control.scaleFactor = 0.92
        // The light runs once around the frame while the panel arrives.
        glow.triggerSweep()
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: control
                property: "travel"
                to: 0
                duration: 480
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: control
                property: "scaleFactor"
                to: 1.0
                duration: 480
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 320
                easing.type: Easing.OutCubic
            }
        }
    }

    // The panel stretches outwards for a moment and is then pulled into
    // its own centre until it disappears.
    exit: Transition {
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    target: control
                    property: "travel"
                    to: control.slideDir * 46
                    duration: 190
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: control
                    property: "scaleFactor"
                    to: 1.12
                    duration: 190
                    easing.type: Easing.OutCubic
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: control
                    property: "travel"
                    to: 0
                    duration: 280
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: control
                    property: "scaleFactor"
                    to: 0.0
                    duration: 280
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: 280
                    easing.type: Easing.InCubic
                }
            }
        }
    }
}
