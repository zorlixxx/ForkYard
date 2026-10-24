import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// The first launch notice.
//
// It has to be acknowledged with an explicit OK before the catalog is
// unlocked, and it cannot be dismissed by accident.
AppDialog {
    id: control
    objectName: "welcomeDialog"

    property string confirmation: ""

    title: "Before you start"
    subtitle: "ForkYard changes how Windows behaves"
    glyph: "octagon-alert"
    accentColor: Theme.color.moderate
    panelWidth: 620
    panelMaxHeight: 640
    showCloseButton: false
    closePolicy: Popup.NoAutoClose
    primaryText: "Accept and continue"
    primaryEnabled: confirmation === "OK"

    onPrimaryClicked: {
        controller.acceptDisclaimer()
        controller.playSound("sucess")
        control.close()
    }

    // The sheet the panel is printed on.
    Image {
        anchors.fill: parent
        source: Assets.ui["tech-grid.png"]
        fillMode: Image.Tile
        opacity: 0.22
        z: -1
    }

    ColumnLayout {
        width: parent ? parent.width : 0
        height: implicitHeight
        spacing: Theme.space.xl

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            Layout.topMargin: Theme.space.xl
            text: "ForkYard applies system optimisations. Read this once before you use it:"
            color: Theme.color.text
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.body
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            spacing: Theme.space.md

                Repeater {
                    model: [
                        "Most entries write to the Windows registry or run a system script.",
                        "Some entries need administrator rights and some need a restart.",
                        "Create a restore point before you apply anything.",
                        "Third party tools are only linked - ForkYard never installs them for you."
                    ]

                RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: Theme.space.lg

                    // The mark of the list, a tick in a small frame.
                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        radius: Theme.radius.sm
                        color: Util.withAlpha(Theme.color.accent, 0.10)
                        border.width: 1
                        border.color: Util.withAlpha(Theme.color.accent, 0.30)

                        IconGlyph {
                            anchors.centerIn: parent
                            iconName: "check"
                            glyphSize: 11
                            tint: Theme.color.accent
                            opacity: 0.85
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData
                        color: Theme.color.textDim
                        font.family: Theme.font.family.ui
                        font.pixelSize: Theme.font.size.bodySmall
                        wrapMode: Text.WordWrap
                        lineHeight: 1.35
                    }
                }
            }
        }

        // The confirmation.  The frame lights up as soon as the word
        // matches.
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            Layout.topMargin: Theme.space.sm
            Layout.preferredHeight: 58
            radius: Theme.radius.control
            color: Util.withAlpha(Theme.color.bgSoft, 0.85)
            border.width: 1
            border.color: control.confirmation === "OK" ? Theme.color.accent : Theme.color.border
            Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }

            // The glow of a confirmed word.
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: parent.radius + 1
                color: "transparent"
                border.width: 2
                border.color: Util.withAlpha(Theme.color.accent, 0.35)
                opacity: control.confirmation === "OK" ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Theme.motion.base } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space.xl
                anchors.rightMargin: Theme.space.lg
                spacing: Theme.space.lg

                Text {
                    text: "Type OK to continue"
                    color: control.confirmation === "OK" ? Theme.color.accent : Theme.color.textDim
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.bodySmall
                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
                }

                Item {
                    Layout.fillWidth: true
                }

                TextField {
                    id: confirmField
                    objectName: "welcomeInput"
                    Layout.preferredWidth: 92
                    implicitHeight: 32
                    placeholderText: "OK"
                    placeholderTextColor: Theme.color.textFaint
                    color: Theme.color.text
                    selectionColor: Util.withAlpha(Theme.color.accent, 0.35)
                    selectedTextColor: Theme.color.text
                    font.family: Theme.font.family.mono
                    font.pixelSize: Theme.font.size.bodySmall
                    font.letterSpacing: 1.5
                    horizontalAlignment: TextInput.AlignHCenter
                    background: Rectangle {
                        radius: Theme.radius.sm + 1
                        color: Theme.color.surface
                        border.width: 1
                        border.color: confirmField.activeFocus ? Theme.color.accent : Theme.color.border
                    }
                    onTextChanged: {
                        control.confirmation = text.trim().toUpperCase()
                        controller.playSound("writting-sfx")
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.space.md
        }
    }
}
