import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "components"
import "./util.js" as Util


Window {
    id: root
    objectName: "mainWindow"

    width: 1440
    height: 900
    minimumWidth: 1080
    minimumHeight: 660
    visible: true
    title: "FORKYARD"
    color: Theme.color.bg

    property bool uiReady: false

    // Conexión: al aceptar el disclaimer, la UI se activa
    Connections {
        target: controller
        function onDisclaimerDone() {
            root.uiReady = true
        }
    }

    // ------------------------------------------------------------ overlay inicial
    // Pantalla negra hasta que se escriba OK en el disclaimer.
    Rectangle {
        id: initialOverlay
        anchors.fill: parent
        color: "black"
        opacity: uiReady ? 0.0 : 1.0
        visible: !uiReady
        z: 100
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }

    // ------------------------------------------------------------ fondo
    // Liquid Chrome: the liquid metal surface of the Forge theme.  It
    // lives under the interface, the pointer steers it and leaves trails.
    LiquidChromeLegacy {
        id: backdrop
        objectName: "liquidChrome"
        anchors.fill: parent
        motionEnabled: root.active
        tintColor: "#a855f7"
        speed: 0.34
        amplitude: 0.3
        frequencyX: 6.1
        frequencyY: 4.5
        detail: 4
        thickness: 0.5
        depth: 1.1
        roughness: 0.5
        exposure: 0.7
        rippleStrength: 0
        rippleSize: 1.3
        tilt: 0.75
    }

    // The pointer of the window steers the surface.  The handler is
    // passive, it never takes the events away from the interface.
    HoverHandler {
        id: backgroundHover
        onHoveredChanged: {
            backdrop.pointerInside = hovered
        }
        onPointChanged: {
            if (!backgroundHover.hovered || backdrop.width <= 0 || backdrop.height <= 0)
                return
            backdrop.pointerX = (backgroundHover.point.position.x / backdrop.width) * 2 - 1
            backdrop.pointerY = (backgroundHover.point.position.y / backdrop.height) * 2 - 1
        }
    }

    // ------------------------------------------------------------ contenido principal
    // Oculto (opacity 0) hasta que uiReady sea true. Cada sección entra desde su lado.
    Item {
        id: mainRoot
        anchors.fill: parent

        ColumnLayout {
            id: mainContent
            anchors.fill: parent
            spacing: 0
            opacity: uiReady ? 1.0 : 0.0
            visible: true
            Behavior on opacity {
                NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
            }

            // ----- Header (entra desde arriba)
            Item {
                Layout.fillWidth: true
                implicitHeight: Theme.layout.headerHeight
                transform: Translate {
                    id: headerTranslate
                    y: uiReady ? 0 : -Theme.layout.headerHeight
                    Behavior on y {
                        NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
                    }
                }
                Header {
                    id: header
                    anchors.fill: parent
                    onSearchChanged: function(text) {
                        root.pendingSearch = text
                        searchDebounce.restart()
                    }
                    onDeveloperRequested: root.openDeveloperMenu()
                }
            }

            // ----- Cuerpo: Sidebar + ContentArea
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Sidebar (entra desde la izquierda)
                Item {
                    id: sidebarHost
                    Layout.preferredWidth: sidebar.expanded ? Theme.layout.sidebarWidth : 12
                    Layout.fillHeight: true
                    clip: true
                    transform: Translate {
                        id: sidebarTranslate
                        x: uiReady ? 0 : -Theme.layout.sidebarWidth
                        Behavior on x {
                            NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
                        }
                    }
                    Behavior on Layout.preferredWidth {
                        NumberAnimation { duration: Theme.motion.base; easing.type: Easing.OutCubic }
                    }

                    Sidebar {
                        id: sidebar
                        anchors.fill: parent
                        onCategoryRequested: function(name) {
                            header.searchField.clear()
                            controller.selectCategory(name)
                        }
                        onRestorePointRequested: controller.createRestorePoint()
                        onElevationRequested: controller.requestElevation()
                        onToggleRequested: sidebar.expanded = !sidebar.expanded
                    }

                    // Collapsed indicator: a slim ember rail with a chevron
                    // that brings the navigation back.
                    Rectangle {
                        id: sidebarRail
                        visible: !sidebar.expanded
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 46
                        color: Util.withAlpha(Theme.color.accent, 0.14)
                        border.width: 1
                        border.color: Util.withAlpha(Theme.color.accent, 0.35)
                        radius: 3

                        IconGlyph {
                            anchors.centerIn: parent
                            iconName: "chevron-right"
                            glyphSize: 11
                            tint: Theme.color.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sidebar.expanded = true
                        }
                    }

                    // Hover trigger zone on the left edge
                    Rectangle {
                        id: sidebarTrigger
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 12
                        color: "transparent"
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: sidebar.expanded = true
                        }
                    }
                }

                // ContentArea (entra desde la derecha)
                    ContentArea {
                        id: content
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        transform: Translate {
                            id: contentTranslate
                            x: uiReady ? 0 : root.width
                            Behavior on x {
                                NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
                            }
                        }
                        onApplyRequested: function(entryId) { root.runEntry(entryId) }
                        onHelpRequested: function(entryId) { root.openHelp(entryId) }
                        onFilterRequested: function(key) { controller.setFilter(key); }
                        onClearFiltersRequested: {
                            controller.setFilter("all")
                            header.searchField.clear()
                        }
                        
                        // Trigger internal reveal after the main slide completes
                        Component.onCompleted: {
                            var timer = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: 700; running: true; repeat: false; onTriggered: content.entranceReady = true }', content)
                            timer.start()
                        }
                    }
            }

            // ----- ActivityPanel (entra desde abajo)
            ActivityPanel {
                id: activity
                Layout.fillWidth: true
                transform: Translate {
                    id: activityTranslate
                    y: uiReady ? 0 : root.height
                    Behavior on y {
                        NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
                    }
                }
                onClearRequested: controller.clearLog()
            }
        }
    }

    // ------------------------------------------------------------ timer y lógica
    property string pendingSearch: ""
    property var promptQueue: []
    property string pendingActionId: ""
    property bool promptResolved: true

    Timer {
        id: searchDebounce
        interval: 140
        onTriggered: controller.setSearchQuery(root.pendingSearch)
    }

    // ------------------------------------------------------------ dialogs
    WelcomeDialog {
        id: welcomeDialog
    }

    HelpDialog {
        id: helpDialog
    }

    ConfirmDialog {
        id: confirmDialog
        onAccepted: {
            root.promptResolved = true
            if (root.promptQueue.length > 0) {
                root.showNextPrompt()
            } else {
                var entryId = root.pendingActionId
                root.pendingActionId = ""
                confirmDialog.close()
                controller.playSound("sucess")
                var plan2 = controller.planTweak(entryId)
                if (plan2 && plan2.isExternal)
                    controller.launchExternal(entryId)
                else if (plan2 && plan2.isCommandLine)
                    controller.executeTweak(entryId)
                else
                    root.startExecution(entryId)
            }
        }
        onClosed: {
            if (!root.promptResolved) {
                root.promptQueue = []
                root.pendingActionId = ""
            }
            root.promptResolved = true
        }
    }

    OutputDialog {
        id: outputDialog
        Connections {
            target: controller
            function onBusyChanged() {
                if (!controller.busy)
                    outputDialog.running = false
            }
        }
    }

    DeveloperMenu {
        id: developerMenu
    }

    // Overlay oscurecido detrás del menú dev.
    // Se dibuja por encima del contenido, pero por debajo del popup, que
    // vive en la capa de overlays de la ventana.
    Rectangle {
        id: devOverlay
        anchors.fill: parent
        color: "black"
        opacity: developerMenu.opened ? 0.38 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
        MouseArea {
            anchors.fill: parent
            enabled: parent.visible
            onClicked: {
                developerMenu.close()
            }
        }
    }

    // -------------------------------------------------------------- logic
    function openDeveloperMenu() {
        developerMenu.anchorX = Math.max(Theme.space.xxl,
                                        root.width - developerMenu.implicitWidth - Theme.space.xxl)
        developerMenu.anchorY = Theme.layout.headerHeight + Theme.space.sm
        developerMenu.open()
    }

    function openHelp(entryId) {
        helpDialog.entryId = entryId
        helpDialog.detail = controller.tweakDetail(entryId)
        controller.playSound("click")
        helpDialog.open()
    }

    function runEntry(entryId) {
        var plan = controller.planTweak(entryId)
        if (!plan || plan.error !== "") {
            controller.playSound("warning")
            return
        }
        controller.playSound("click")
        if (plan.isExternal) {
            root.pendingActionId = entryId
            root.promptQueue = (plan.prompts || []).slice(0)
            if (root.promptQueue.length === 0) {
                controller.launchExternal(entryId)
                root.pendingActionId = ""
                return
            }
            root.promptResolved = false
            root.showNextPrompt()
            return
        }
        root.pendingActionId = entryId
        root.promptQueue = (plan.prompts || []).slice(0)
        if (root.promptQueue.length === 0) {
            if (plan.isCommandLine) {
                controller.executeTweak(entryId)
            } else {
                root.startExecution(entryId)
            }
            root.pendingActionId = ""
            return
        }
        root.promptResolved = false
        root.showNextPrompt()
    }

    function startExecution(entryId) {
        outputDialog.entryName = entryId
        outputDialog.running = true
        outputDialog.log = []
        outputDialog.open()
        controller.executeTweak(entryId)
    }

    function showNextPrompt() {
        if (root.promptQueue.length === 0) {
            confirmDialog.close()
            return
        }
        var prompt = root.promptQueue.shift()
        confirmDialog.promptTitle = prompt.title
        confirmDialog.promptBody = prompt.body
        confirmDialog.promptKind = prompt.kind
        confirmDialog.confirmLabel = prompt.confirmLabel
        if (!confirmDialog.visible) {
            confirmDialog.open()
        }
    }

    Component.onCompleted: {
        if (!controller.disclaimerAccepted) {
            welcomeDialog.open()
        } else {
            root.uiReady = true
        }
    }
}
