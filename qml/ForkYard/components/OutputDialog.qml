import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// A visible terminal-style output panel for command-line actions.
//
// It streams genuine output from a running .bat/.cmd/command process so
// the user can see progress, warnings and errors as they happen, and can
// tell whether the process is still running, completed or failed.
// Closing the panel never terminates a process that is still running.
Popup {
    id: control
    objectName: "outputDialog"

    property string entryName: ""
    property bool running: false
    property int exitCode: -1
    property color accentColor: Theme.color.accent

    // -1 = the panel enters from the top, 1 = it enters from the bottom.
    property int slideDir: 1
    property real travel: 0
    property real scaleFactor: 1.0

    modal: true
    padding: 0
    dim: true
    closePolicy: Popup.NoAutoClose
    focus: true

    x: Math.round(((parent ? parent.width : 1440) - width) / 2)
    y: Math.round(((parent ? parent.height : 900) - height) / 2)

    Overlay.modal: Rectangle {
        color: Util.withAlpha(Theme.color.scrim, 0.74)
    }

    width: Math.min(740, parent ? parent.width * 0.85 : 740)
    implicitHeight: 520

    background: Item {
    }

    contentItem: Item {
        id: outputPanel

        transformOrigin: Item.Center
        transform: [
            Translate {
                id: outputShift
                x: 0
                y: control.travel
            },
            Scale {
                origin.x: outputPanel.width / 2
                origin.y: outputPanel.height / 2
                xScale: control.scaleFactor
                yScale: control.scaleFactor
            }
        ]

        // The border glow: light travels around the frame of the panel.
        BorderGlow {
            id: glow
            anchors.fill: parent
            radius: Theme.radius.dialog
            intensity: 0.7
            coneSpread: 48
            sparks: 14
            interactive: true
            alwaysOn: true
        }

        // The solid base of the panel.
        Rectangle {
            anchors.fill: parent
            color: Theme.color.surface
            radius: Theme.radius.dialog
        }

        // A sheet of glass on top of it.
        GlassPanel {
            anchors.fill: parent
            radius: Theme.radius.dialog
            shadow: false
            borderGlow: false
        }

        ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ------------------------------------------------------ header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            Layout.topMargin: Theme.space.xl
            Layout.bottomMargin: Theme.space.sm
            spacing: Theme.space.lg

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: Theme.radius.sm + 2
                color: Util.withAlpha(control.accentColor, 0.14)
                border.width: 1
                border.color: Util.withAlpha(control.accentColor, 0.35)

                IconGlyph {
                    anchors.centerIn: parent
                    iconName: "activity"
                    glyphSize: 17
                    tint: control.accentColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: control.entryName.length > 0 ? "Running: " + control.entryName : "Command output"
                    color: Theme.color.text
                    font.family: Theme.font.family.display
                    font.pixelSize: Theme.font.size.dialogTitle
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: control.running ? "Process is running…"
                                          : (control.exitCode === 0 ? "Completed successfully."
                                                                      : (control.exitCode > 0 ? "Completed with errors (exit " + control.exitCode + ")."
                                                                                              : "Did not complete."))
                    color: Theme.color.textFaint
                    font.family: Theme.font.family.ui
                    font.pixelSize: Theme.font.size.label
                    elide: Text.ElideRight
                }
            }

            IconButton {
                objectName: "outputClose"
                visible: !control.running
                iconName: "x"
                buttonSize: 28
                quiet: true
                tint: Theme.color.textFaint
                hoverTint: Theme.color.text
                onClicked: control.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.color.border
            Layout.topMargin: Theme.space.sm
            Layout.bottomMargin: Theme.space.sm
        }

        // ------------------------------------------------------- output
        ListView {
            id: outputList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            Layout.bottomMargin: Theme.space.xl
            clip: true
            model: control.log
            spacing: 1
            boundsBehavior: Flickable.StopAtBounds

            delegate: Text {
                width: outputList.width
                text: modelData
                color: modelData.toLowerCase().indexOf("error") >= 0
                       ? Theme.color.advanced
                       : Theme.color.textDim
                font.family: Theme.font.family.mono
                font.pixelSize: Theme.font.size.mono
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }

            onCountChanged: positionViewAtEnd()
        }

        // ------------------------------------------------------- footer
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            Layout.topMargin: Theme.space.sm
            Layout.bottomMargin: Theme.space.xl
            spacing: Theme.space.md

            Item {
                Layout.fillWidth: true
            }

                AppButton {
                    objectName: "outputCloseBtn"
                    text: control.running ? "Stop watching" : "Close"
                    variant: "secondary"
                    onClicked: {
                        if (!control.running)
                            control.close()
                    }
                }
        }
        }
    }

    // Streamed command output lines.
    property var log: []

    Connections {
        target: controller
        function onOutputLine(line) {
            if (control.visible)
                control.log.push(line)
        }
    }

    Component.onCompleted: {
        control.log = []
    }

    onAboutToShow: {
        control.slideDir = Math.random() > 0.5 ? -1 : 1
        var distance = (control.height > 0 ? control.height : 520) + 48
        control.travel = control.slideDir * distance
        control.scaleFactor = 0.94
        glow.triggerSweep()
    }

    onClosed: {
        controller.playSound("close")
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: control
                property: "travel"
                to: 0
                duration: 460
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: control
                property: "scaleFactor"
                to: 1.0
                duration: 460
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    // The panel stretches for a moment and is then pulled into its centre.
    exit: Transition {
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    target: control
                    property: "travel"
                    to: control.slideDir * 40
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: control
                    property: "scaleFactor"
                    to: 1.10
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: control
                    property: "travel"
                    to: 0
                    duration: 260
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: control
                    property: "scaleFactor"
                    to: 0.0
                    duration: 260
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: 260
                    easing.type: Easing.InCubic
                }
            }
        }
    }
}
