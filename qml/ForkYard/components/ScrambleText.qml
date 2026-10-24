import QtQuick

// Texto que aparece letra a letra con un efecto de "scramble":
// los caracteres no revelados aún muestran letras aleatorias que se
// estabilizan de izquierda a derecha hasta formar la palabra final.
Item {
    id: root

    property string text: ""
    property int speed: 35           // ms entre cada letra revelada
    property color color: Theme.color.text
    property real fontSize: Theme.font.size.title
    property string fontFamily: Theme.font.family.ui
    property bool active: true
    property bool centered: true

    // The item has to announce its own height, otherwise a layout gives
    // it no room at all and the text lands on top of the next line.
    implicitHeight: Math.round(fontSize * 1.32)

    // Índice de cuántos caracteres están ya "revelados" (fijos).
    property int revealed: 0
    // Tiempo total transcurrido para calcular letras aleatorias.
    property int ticker: 0

    readonly property string alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    // El texto mostrado: revelados + aleatorios para el resto.
    readonly property string displayText: {
        if (!active || text.length === 0)
            return text
        var out = ""
        for (var i = 0; i < text.length; ++i) {
            if (i < revealed)
                out += text.charAt(i)
            else
                out += alphabet.charAt(Math.floor(Math.random() * alphabet.length))
        }
        return out
    }

    Timer {
        id: scrambleTimer
        interval: root.speed
        repeat: true
        running: root.active && root.text.length > 0 && root.revealed < root.text.length
        onTriggered: {
            root.ticker += root.speed
            if (root.revealed < root.text.length) {
                // Revelar una letra más cada ciertos ticks (para ir más lento al principio).
                if (root.ticker % (root.speed * 2) === 0) {
                    root.revealed += 1
                }
            }
        }
    }

    Text {
        anchors.fill: parent
        text: root.displayText
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.weight: Font.DemiBold
        horizontalAlignment: root.centered ? Text.AlignHCenter : Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
    }

    Component.onCompleted: {
        if (root.text.length > 0) {
            root.revealed = 0
            root.ticker = 0
            scrambleTimer.running = true
        }
    }
}
