import QtQuick
import QtQuick.Layouts
import "../util.js" as Util

// The top bar: brand, global search and the developer menu.
Item {
    id: root

    signal searchChanged(string text)
    signal developerRequested()

    property alias searchField: search

    implicitHeight: Theme.layout.headerHeight

    Rectangle {
        anchors.fill: parent
        color: Util.withAlpha(Theme.color.surface, 0.45)
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Util.withAlpha("#ffffff", 0.10)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space.xxl
        anchors.rightMargin: Theme.space.xxl
        spacing: Theme.space.lg

        // ------------------------------------------------------------ brand
        Item {
            id: logoArea
            width: 32
            height: 32

            property bool hovered: logoMouse.containsMouse
            property bool pressed: false

            // Warm halo behind the mark while it is hovered.
            Rectangle {
                anchors.centerIn: parent
                width: 40
                height: 40
                radius: 20
                color: Util.withAlpha(Theme.color.accent, 0.10)
                opacity: logoArea.hovered ? 1.0 : 0.0
                scale: logoArea.hovered ? 1.0 : 0.75
                Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
            }

            Image {
                id: logoImg
                objectName: "brandMark"
                anchors.centerIn: parent
                source: Assets.forkyardIcon
                sourceSize.width: 128
                sourceSize.height: 128
                width: 28
                height: 28
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                transformOrigin: Item.Center
                rotation: logoArea.hovered ? 12 : (logoArea.pressed ? 8 : 0)
                scale: logoArea.hovered ? 1.12 : (logoArea.pressed ? 0.9 : 1.0)
                Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
            }

            // Glow ring on hover
            Rectangle {
                anchors.centerIn: parent
                width: 36
                height: 36
                radius: 18
                color: "transparent"
                border.width: 2
                border.color: Util.withAlpha(Theme.color.accent, 0.6)
                opacity: logoArea.hovered ? 1.0 : 0.0
                scale: logoArea.hovered ? 1.0 : 0.8
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }

            MouseArea {
                id: logoMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressedChanged: { logoArea.pressed = pressed }
                onClicked: {
                    logoArea.pressed = false
                    controller.playSound("click logo forkyard button")
                }
            }
        }

        // The wordmark never floats: the brand has to stay still.
        Text {
            id: wordmark
            text: "FORKYARD"
            color: Theme.color.text
            font.family: Theme.font.family.display
            font.pixelSize: Theme.font.size.wordmark
            font.letterSpacing: Theme.font.tracking.wordmark
            font.weight: Font.DemiBold
            opacity: 1.0
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: versionLabel.implicitWidth + Theme.space.lg
            implicitHeight: versionLabel.implicitHeight + Theme.space.sm
            radius: Theme.radius.pill
            color: Util.withAlpha(Theme.color.textFaint, 0.12)
            border.width: 1
            border.color: Util.withAlpha(Theme.color.textFaint, 0.22)

            Text {
                id: versionLabel
                anchors.centerIn: parent
                text: "v" + appVersion
                color: Theme.color.textFaint
                font.family: Theme.font.family.ui
                font.pixelSize: Theme.font.size.micro
                font.weight: Font.DemiBold
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // The search rests as a magnifier and unfolds on hover.
        SearchField {
            id: search
            Layout.preferredWidth: search.expanded ? search.expandedWidth : search.collapsedWidth
            expandedWidth: Math.min(360, root.width * 0.28)
            onSearchChanged: function(text) { root.searchChanged(text) }

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }
        }

        // Busy spinner
        Item {
            id: busySpinner
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            visible: controller.busy
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }

            // The track of the ring.
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Util.withAlpha(Theme.color.accent, 0.22)
            }

            // The light that runs around the ring.
            Rectangle {
                id: ringArc
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.color.accent
                opacity: 0.9
                // A quarter of the ring is lit, the rest fades away.
                transform: Rotation {
                    origin.x: width / 2
                    origin.y: height / 2
                    angle: 0
                    NumberAnimation on angle {
                        running: controller.busy
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // The core of the spinner.
            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: Theme.color.accent

                SequentialAnimation on scale {
                    running: controller.busy
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.55; duration: 450; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 450; easing.type: Easing.InOutSine }
                }
            }
        }

        // ------------------------------------------------- developer trigger
        // The button only announces the request; the menu itself is a popup
        // that lives in the window, so it can never be hidden behind the
        // content of the page.
        Item {
            id: devArea
            objectName: "developerButton"
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            property bool hovered: devMouse.containsMouse
            property real devClickScale: 1.0

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius.control
                color: devArea.hovered ? Util.withAlpha(Theme.color.surfaceHi, 0.45)
                                       : Util.withAlpha(Theme.color.surface, 0.30)
                border.width: 1
                border.color: devArea.hovered ? Util.withAlpha(Theme.color.accent, 0.45)
                                              : Util.withAlpha("#ffffff", 0.12)
                Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
                Behavior on border.color { ColorAnimation { duration: Theme.motion.fast } }

                // Accent halo that blooms while the button is hovered.
                Rectangle {
                    anchors.centerIn: parent
                    width: 42
                    height: 42
                    radius: 21
                    color: "transparent"
                    border.width: 1
                    border.color: Util.withAlpha(Theme.color.accent, 0.40)
                    opacity: devArea.hovered ? 1.0 : 0.0
                    scale: devArea.hovered ? 1.0 : 0.7
                    Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
                    Behavior on scale { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
                }

                IconGlyph {
                    id: devIcon
                    anchors.centerIn: parent
                    iconName: "circle-user"
                    glyphSize: 18
                    tint: devArea.hovered ? Theme.color.accent : Theme.color.textDim
                    Behavior on tint { ColorAnimation { duration: Theme.motion.fast } }
                    transform: [
                        Rotation {
                            origin.x: 9
                            origin.y: 9
                            angle: devArea.hovered ? 360 : 0
                            Behavior on angle { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                        },
                        Scale {
                            origin.x: 9
                            origin.y: 9
                            xScale: devArea.devClickScale
                            yScale: devArea.devClickScale
                            Behavior on xScale { NumberAnimation { duration: 250; easing.type: Easing.OutBounce } }
                            Behavior on yScale { NumberAnimation { duration: 250; easing.type: Easing.OutBounce } }
                        }
                    ]
                }
            }

            MouseArea {
                id: devMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    devArea.devClickScale = 0.7
                    devClickResetTimer.restart()
                    controller.playSound("dev-select")
                    root.developerRequested()
                }
            }

            Timer {
                id: devClickResetTimer
                interval: 250
                repeat: false
                onTriggered: devArea.devClickScale = 1.0
            }
        }
    }
}
