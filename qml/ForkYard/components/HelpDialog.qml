import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../util.js" as Util

// The help panel of a single entry.
//
// It explains what the entry does, how ForkYard applies it, which
// privileges and restarts it needs and - where a real procedure exists -
// how to undo it.
//
// The panel is built like a technical sheet: a hairline grid behind the
// text, a light that scans down the page when it opens and the
// requirements laid out as a specification table.
AppDialog {
    id: control
    objectName: "helpDialog"

    property var detail: ({})
    property string entryId: ""

    title: detail.name || "Details"
    subtitle: detail.category || ""
    glyph: "info"
    panelWidth: 660
    panelMaxHeight: 660
    primaryText: detail.url ? "Open official page" : ""
    tertiaryText: "Copy details"

    onPrimaryClicked: {
        if (detail.url)
            controller.openUri(detail.url)
        controller.playSound("click")
        control.close()
    }
    onTertiaryClicked: {
        controller.playSound("click")
        controller.copyToClipboard(control.plainText())
    }

    onClosed: {
        controller.playSound("close")
    }

    function plainText() {
        var lines = []
        lines.push(detail.name || "")
        lines.push(detail.description || "")
        var sections = detail.sections || []
        for (var i = 0; i < sections.length; ++i) {
            var section = sections[i]
            lines.push("")
            lines.push(section.title.toUpperCase())
            if (section.body)
                lines.push(section.body)
            var rows = section.rows || []
            for (var r = 0; r < rows.length; ++r)
                lines.push(rows[r][0] + ": " + rows[r][1])
            var steps = section.steps || []
            for (var s = 0; s < steps.length; ++s)
                lines.push((s + 1) + ". " + steps[s])
            if (section.link)
                lines.push(section.link)
        }
        return lines.join("\n")
    }

    // ------------------------------------------------------------- content
    // The sheet of graph paper the text is printed on.
    Image {
        anchors.fill: parent
        source: Assets.ui["tech-grid.png"]
        fillMode: Image.Tile
        opacity: 0.3
        z: -1
    }

    // The margin rule of the sheet.
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: Theme.space.md
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        radius: 1
        z: -1
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Util.withAlpha(Theme.color.accent, 0.0) }
            GradientStop { position: 0.25; color: Util.withAlpha(Theme.color.accent, 0.55) }
            GradientStop { position: 0.8; color: Util.withAlpha(Theme.color.accent, 0.25) }
            GradientStop { position: 1.0; color: Util.withAlpha(Theme.color.accent, 0.0) }
        }
    }

    // The scan of light that runs down the page when the panel opens.
    Rectangle {
        id: scan
        anchors.left: parent.left
        anchors.right: parent.right
        height: 110
        y: -height
        opacity: 0
        z: 2

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Util.withAlpha(Theme.color.accent, 0.22) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        SequentialAnimation {
            id: scanAnimation
            NumberAnimation {
                target: scan
                property: "y"
                from: -scan.height
                to: scan.parent ? scan.parent.height : 400
                duration: 1500
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: scan
                property: "opacity"
                from: 1
                to: 0
                duration: 450
            }
        }
    }

    onOpened: scanAnimation.restart()

    Flickable {
        id: body
        anchors.fill: parent
        contentWidth: width
        contentHeight: sections.implicitHeight
        // The panel is only as tall as the content, and the content scrolls
        // when it does not fit.
        implicitHeight: contentHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: sections
            width: body.width
            spacing: Theme.space.xl

            // The sheet of the panel: a hairline grid, barely there.
            Image {
                Layout.fillWidth: true
                Layout.preferredHeight: 0
                source: ""
                visible: false
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.xl
                Layout.leftMargin: Theme.space.xxl
                Layout.rightMargin: Theme.space.xxl
                text: control.detail.description || ""
                color: Theme.color.text
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.body + 1
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                lineHeight: 1.4
            }

            Repeater {
                model: control.detail.sections || []

                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.space.xxl
                    Layout.rightMargin: Theme.space.xxl
                    spacing: Theme.space.md

                    // The heading of a section: a short accent bar and a
                    // letter spaced label.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Theme.space.xs
                        spacing: Theme.space.md

                        Rectangle {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 2
                            radius: 1
                            color: Theme.color.accent
                            opacity: 0.85
                        }

                        Text {
                            text: modelData.title.toUpperCase()
                            color: Theme.color.accent
                            font.family: Theme.font.family.ui
                            font.pixelSize: Theme.font.size.micro
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.font.tracking.micro + 0.6
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Util.withAlpha(Theme.color.accent, 0.15)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: modelData.body !== undefined
                        text: modelData.body || ""
                        color: Theme.color.textDim
                        font.family: Theme.font.family.ui
                        font.pixelSize: Theme.font.size.bodySmall
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                    }

                    // The requirements read like a specification table:
                    // a marked key on the left, the value on the right.
                    Repeater {
                        model: modelData.rows || []

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: rowValue.implicitHeight + Theme.space.md * 2
                            radius: Theme.radius.sm
                            color: Util.withAlpha(Theme.color.accent, 0.05)
                            border.width: 1
                            border.color: Util.withAlpha(Theme.color.accent, 0.14)

                            RowLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.space.md
                                spacing: Theme.space.lg

                                Rectangle {
                                    Layout.preferredWidth: 5
                                    Layout.preferredHeight: 5
                                    radius: 2.5
                                    color: Theme.color.accent
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 5
                                }

                                Text {
                                    Layout.preferredWidth: 108
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 1
                                    text: modelData[0]
                                    color: Theme.color.text
                                    font.family: Theme.font.family.ui
                                    font.pixelSize: Theme.font.size.label
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    id: rowValue
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    text: modelData[1]
                                    color: Theme.color.textDim
                                    font.family: Theme.font.family.ui
                                    font.pixelSize: Theme.font.size.bodySmall
                                    wrapMode: Text.WordWrap
                                    lineHeight: 1.35
                                }
                            }
                        }
                    }

                    Repeater {
                        model: modelData.steps || []

                        RowLayout {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: Theme.space.lg

                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: 11
                                color: Util.withAlpha(Theme.color.accent, 0.12)
                                border.width: 1
                                border.color: Util.withAlpha(Theme.color.accent, 0.36)

                                Text {
                                    anchors.centerIn: parent
                                    text: index + 1
                                    color: Theme.color.accent
                                    font.family: Theme.font.family.ui
                                    font.pixelSize: Theme.font.size.micro
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                color: Theme.color.textDim
                                font.family: Theme.font.family.ui
                                font.pixelSize: Theme.font.size.bodySmall
                                wrapMode: Text.WordWrap
                                lineHeight: 1.4
                            }
                        }
                    }

                    // The source of the tool, as a link that can be read.
                    Rectangle {
                        Layout.fillWidth: true
                        visible: modelData.link !== undefined
                        Layout.preferredHeight: linkText.implicitHeight + Theme.space.md * 2
                        radius: Theme.radius.sm
                        color: Util.withAlpha(Theme.color.info, 0.07)
                        border.width: 1
                        border.color: Util.withAlpha(Theme.color.info, 0.22)

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.space.md
                            spacing: Theme.space.md

                            IconGlyph {
                                iconName: "arrow-right"
                                glyphSize: 12
                                tint: Theme.color.info
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                id: linkText
                                Layout.fillWidth: true
                                text: modelData.link || ""
                                color: Theme.color.info
                                font.family: Theme.font.family.mono
                                font.pixelSize: Theme.font.size.mono
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.space.xl
            }
        }
    }
}
