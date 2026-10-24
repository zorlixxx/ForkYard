import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// The confirmation that precedes a risky action.
//
// The same component serves the risk confirmation, the manual import
// note and the restart notice; only the wording and the buttons differ.
// The body is laid out like a short sheet: the question, the risk as a
// chip and the explanation.
AppDialog {
    id: control
    objectName: "confirmDialog"

    property string promptTitle: ""
    property string promptBody: ""
    property string promptKind: "confirm"
    property string confirmLabel: "Apply"

    // The body arrives in three parts.
    readonly property var parts: (promptBody || "").split("\n\n")
    readonly property string question: parts.length > 0 ? parts[0] : ""
    readonly property string riskLabel: parts.length > 1
                                          ? parts[1].replace("Risk level:", "").trim() : ""
    readonly property string explanation: parts.length > 2 ? parts[2] : ""
    readonly property color riskTint: riskLabel.indexOf("Advanced") >= 0 ? Theme.color.advanced
                                        : (riskLabel.indexOf("Moderate") >= 0 ? Theme.color.moderate
                                                                            : Theme.color.safe)

    title: promptTitle
    glyph: promptKind === "confirm" ? "octagon-alert" : "info"
    accentColor: promptKind === "confirm" ? Theme.color.moderate : Theme.color.info
    panelWidth: 540
    panelMaxHeight: 560
    primaryText: confirmLabel
    // A confirmation is read, not decoded.
    scrambleTitle: false

    onPrimaryClicked: {
        controller.playSound("confirm")
        control.accepted()
    }

    // The dialog is closed with the cross, so a dismissed prompt plays
    // the undo sound.
    onClosed: {
        controller.playSound("undo")
    }

    signal accepted()

    // The sheet of the panel.
    Image {
        anchors.fill: parent
        source: Assets.ui["tech-grid.png"]
        fillMode: Image.Tile
        opacity: 0.18
        z: -1
    }

    ColumnLayout {
        width: parent ? parent.width : 0
        height: implicitHeight
        spacing: Theme.space.lg

        // The question.
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            Layout.topMargin: Theme.space.xl
            text: control.question
            color: Theme.color.text
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.body + 1
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            lineHeight: 1.35
        }

        // The risk of the entry, as a chip.
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            visible: control.riskLabel !== ""
            spacing: Theme.space.md

            Text {
                text: "RISK LEVEL"
                color: Theme.color.textFaint
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.micro
                font.weight: Font.DemiBold
                font.letterSpacing: Theme.font.tracking.micro
            }

            Pill {
                text: control.riskLabel
                uppercase: true
                tint: control.riskTint
                filled: true
            }
        }

        // What the entry is about to do.
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.space.xxl
            Layout.rightMargin: Theme.space.xxl
            Layout.bottomMargin: Theme.space.md
            text: control.explanation
            color: Theme.color.textDim
            font.family: Theme.font.family.ui
            font.pixelSize: Theme.font.size.body
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            lineHeight: 1.45
        }
    }
}
