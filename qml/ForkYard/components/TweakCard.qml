import QtQuick
import QtQuick.Effects
import "../util.js" as Util
import QtQuick.Controls.Basic
import QtQuick.Layouts

// One optimisation entry.
//
// The card answers the questions a user actually has: what it does, how
// risky it is, which Windows versions it applies to, whether it needs
// administrator rights or a restart, what the primary action is and where
// the detailed documentation lives.
Item {
    id: root
    objectName: "card-" + (entry.id || "")

    property var entry: ({})
    property string logoSource: ""
    property int cardHeight: Theme.layout.cardHeight + 20
    property int index: 0
    property real tiltX: 0
    property real tiltY: 0
    property real maxTilt: 8

    signal applyRequested(string entryId)
    signal helpRequested(string entryId)

    readonly property color riskTint: {
        if (entry.risk === "Advanced")
            return Theme.color.advanced
        if (entry.risk === "Moderate")
            return Theme.color.moderate
        return Theme.color.safe
    }

    implicitHeight: cardHeight
    implicitWidth: 200

    // The card leans with the pointer.  A three dimensional rotation only
    // shrinks the silhouette, it never grows, so the grid cannot cut a
    // corner off it.
    transform: [
        Rotation { origin.x: root.width/2; origin.y: root.height/2; axis { x: 1; y: 0; z: 0 } angle: root.tiltX },
        Rotation { origin.x: root.width/2; origin.y: root.height/2; axis { x: 0; y: 1; z: 0 } angle: root.tiltY }
    ]
    Behavior on tiltX { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on tiltY { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // ------------------------------------------------------------- surface
    // The card is a sheet of glass: a translucent body, a light border,
    // an inner bevel and a highlight that follows the pointer.
    GlassPanel {
        id: surface
        anchors.fill: parent
        radius: Theme.radius.card
        hovered: cardArea.containsMouse
        tint: Theme.color.accent
        // A dark base keeps the text readable while the background moves.
        baseColor: Util.withAlpha(Theme.color.bg, 0.55)
    }

    MouseArea {
        id: cardArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: {
            var cx = mouse.x - width / 2
            var cy = mouse.y - height / 2
            root.tiltY = -(cx / Math.max(width,1)) * root.maxTilt
            root.tiltX = (cy / Math.max(height,1)) * root.maxTilt
        }
        onExited: {
            root.tiltX = 0
            root.tiltY = 0
        }
    }

    // ------------------------------------------------------------- contents
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space.xl
        anchors.rightMargin: Theme.space.xl
        anchors.topMargin: Theme.space.xl
        anchors.bottomMargin: Theme.space.xl
        spacing: Theme.space.xl

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.xl

            // Logo / icon
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                Layout.alignment: Qt.AlignTop
                radius: Theme.radius.sm + 4
                color: "transparent"
                border.width: 1
                border.color: Theme.color.border

                // The tile fills with light while the card is hovered.
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Util.withAlpha(Theme.color.accent, cardArea.containsMouse ? 0.20 : 0.07) }
                        GradientStop { position: 1.0; color: Util.withAlpha(Theme.color.surfaceHi, 0.9) }
                    }
                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
                }

                // The glow behind the mark.
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 14
                    height: parent.height + 14
                    radius: (parent.width + 14) / 2
                    color: Util.withAlpha(Theme.color.accent, 0.18)
                    opacity: cardArea.containsMouse ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Theme.motion.base } }
                }

                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    visible: root.logoSource !== ""
                    source: root.logoSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    sourceSize.width: 48
                    sourceSize.height: 48
                }

                IconGlyph {
                    anchors.centerIn: parent
                    visible: root.logoSource === ""
                    iconName: root.entry.isExternal ? "arrow-right" : "cog"
                    glyphSize: 20
                    tint: cardArea.containsMouse ? Theme.color.accent : Theme.color.textDim
                    Behavior on tint { ColorAnimation { duration: Theme.motion.fast } }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.space.sm + 2

                Text {
                    Layout.fillWidth: true
                    text: root.entry.name || ""
                    color: Theme.color.text
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.title
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    lineHeight: 1.15
                }

                Text {
                    Layout.fillWidth: true
                    text: root.entry.description || ""
                    color: Theme.color.textDim
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.bodySmall
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    lineHeight: 1.3
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.sm

                    Pill {
                        text: root.entry.risk || "Safe"
                        uppercase: true
                        tint: root.riskTint
                        filled: true
                    }

                    Pill {
                        visible: entry.isExternal
                        text: "External"
                        iconName: "arrow-right"
                        tint: Theme.color.info
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }

            // Action buttons grouped on the right.
            RowLayout {
                Layout.alignment: Qt.AlignTop
                spacing: Theme.space.sm

                AppButton {
                    objectName: "apply-" + (root.entry.id || "")
                    text: root.entry.action || "Apply"
                    iconName: root.entry.isExternal ? "arrow-right" : "check"
                    variant: root.entry.isExternal ? "secondary" : "primary"
                    controlHeight: 32
                    buttonPadding: Theme.space.xl
                    onClicked: {
                        controller.playSound("click")
                        root.applyRequested(root.entry.id)
                    }
                }

                IconButton {
                    objectName: "help-" + (root.entry.id || "")
                    iconName: "info"
                    buttonSize: 32
                    quiet: true
                    tint: Theme.color.textFaint
                    hoverTint: Theme.color.accent
                    onClicked: {
                        controller.playSound("info-button")
                        root.helpRequested(root.entry.id)
                    }
                }
            }
        }

        // Badges and category metadata, wrapped so they never overflow.
        Flow {
            Layout.fillWidth: true
            spacing: Theme.space.sm

            Repeater {
                model: root.entry.badges || []

                Pill {
                    required property var modelData
                    text: modelData.text
                    iconName: modelData.icon
                    tint: modelData.text === "Admin" ? Theme.color.moderate : Theme.color.textFaint
                }
            }

            Text {
                visible: root.entry.category !== undefined && root.entry.category !== ""
                text: root.entry.category || ""
                color: Theme.color.textFaint
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.micro
                font.weight: Font.DemiBold
            }
        }
    }

    // ------------------------------------------------------------- entrance
    // Staggered fade-in so the grid settles in gently rather than popping.
    property bool visibleNow: false
    
    opacity: visibleNow ? 1.0 : 0.0
    scale: visibleNow ? 1.0 : 0.92
    
    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

    Component.onCompleted: {
        // Stagger the reveal based on index
        var delay = index * 60
        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: ' + delay + '; running: true; repeat: false; onTriggered: root.visibleNow = true }', root)
        timer.start()
    }
}
