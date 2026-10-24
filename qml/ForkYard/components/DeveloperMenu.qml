import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// The developer menu.
//
// It is anchored to the header and lives inside the main window, so it
// never opens a second top level window and it can never be covered by
// the content of the page.
Popup {
    id: control
    objectName: "developerMenu"

    property real anchorX: 0
    property real anchorY: 0

    implicitWidth: 320
    modal: false
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: anchorX
    y: anchorY

    // ------------------------------------------------------------ backdrop
    background: Item {
        // The border glow: a light runs around the frame of the menu.
        BorderGlow {
            id: glow
            anchors.fill: parent
            radius: Theme.radius.panel
            intensity: 0.8
            coneSpread: 50
            sparks: 14
            interactive: true
            alwaysOn: true
        }

        // Soft ember halo that bleeds out of the panel.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            radius: Theme.radius.panel + 10
            gradient: Gradient {
                GradientStop { position: 0.0; color: Util.withAlpha(Theme.color.accent, 0.18) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.panel
            gradient: Gradient {
                GradientStop { position: 0.0; color: Util.withAlpha(Theme.color.surfaceHi, 0.97) }
                GradientStop { position: 1.0; color: Util.withAlpha(Theme.color.bgSoft, 0.97) }
            }
            border.width: 1
            border.color: Util.withAlpha("#ffffff", 0.16)
        }

        // Accent hairline that marks the top edge of the panel.
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            color: Util.withAlpha(Theme.color.accent, 0.55)
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ------------------------------------------------------------ title
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            Layout.leftMargin: Theme.space.xl
            Layout.rightMargin: Theme.space.xl

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space.md

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.color.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "DEVELOPER"
                    color: Theme.color.textFaint
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.micro
                    font.weight: Font.DemiBold
                    font.letterSpacing: Theme.font.tracking.micro
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "v" + appVersion
                    color: Theme.color.textFaint
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.micro
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.color.border
        }

        // ------------------------------------------------------------ links
        Repeater {
            model: controller.developerLinks

            AbstractButton {
                id: linkButton
                required property var modelData

                readonly property color linkTint: modelData.accent
                        ? modelData.accent
                        : Theme.color.accent

                Layout.fillWidth: true
                Layout.preferredHeight: 62
                implicitHeight: 62

                background: Rectangle {
                    radius: Theme.radius.control
                    color: linkButton.hovered ? Util.withAlpha(linkButton.linkTint, 0.12) : "transparent"
                    border.width: linkButton.hovered ? 1 : 0
                    border.color: Util.withAlpha(linkButton.linkTint, 0.45)
                    Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
                    Behavior on border.width { NumberAnimation { duration: Theme.motion.fast } }
                }

                contentItem: Item {
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space.lg
                        anchors.rightMargin: Theme.space.lg
                        spacing: Theme.space.lg

                        // Icon tile with the brand glyph of the link.
                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: Theme.radius.sm + 3
                            color: Util.withAlpha(linkButton.linkTint, linkButton.hovered ? 0.22 : 0.12)
                            border.width: 1
                            border.color: Util.withAlpha(linkButton.linkTint, linkButton.hovered ? 0.55 : 0.25)
                            Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }

                            scale: linkButton.hovered ? 1.06 : 1.0
                            Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }

                            IconGlyph {
                                anchors.centerIn: parent
                                iconName: linkButton.modelData.icon
                                           ? linkButton.modelData.icon : "globe"
                                glyphSize: linkButton.hovered ? 19 : 17
                                tint: linkButton.hovered ? linkButton.linkTint : Theme.color.textDim
                                Behavior on glyphSize { NumberAnimation { duration: Theme.motion.fast } }
                                Behavior on tint { ColorAnimation { duration: Theme.motion.fast } }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: linkButton.modelData.label
                                color: linkButton.hovered ? Theme.color.text : Theme.color.textDim
                                font.family: Theme.font.family.ui
                                font.pixelSize: linkButton.hovered ? Theme.font.size.body + 1 : Theme.font.size.body
                                font.weight: Font.DemiBold
                                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
                                Behavior on font.pixelSize { NumberAnimation { duration: Theme.motion.fast } }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: linkButton.modelData.hint
                                color: Theme.color.textFaint
                                font.family: Theme.font.family.ui
                                font.pixelSize: Theme.font.size.micro
                                elide: Text.ElideRight
                            }
                        }

                        // Arrow that slides in when the row is hovered.
                        Item {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18

                            IconGlyph {
                                anchors.centerIn: parent
                                iconName: "arrow-right"
                                glyphSize: 15
                                tint: linkButton.linkTint
                                opacity: linkButton.hovered ? 1.0 : 0.0
                                x: linkButton.hovered ? 0 : -5
                                Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
                                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }

                onClicked: {
                    controller.playSound("click")
                    controller.openUri(linkButton.modelData.url)
                    control.close()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.color.border
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 34

            Text {
                anchors.centerIn: parent
                text: "ForkYard " + appVersion
                color: Theme.color.textFaint
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.micro
            }
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Theme.motion.fast
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.94
                to: 1.0
                duration: 260
                easing.type: Easing.OutBack
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: Theme.motion.instant
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.96
                duration: Theme.motion.instant
                easing.type: Easing.InCubic
            }
        }
    }
}
