import QtQuick

// Registers the rounded face Atoll uses for its header (".system(.headline,
// design: .rounded)"). SF Rounded has no Linux equivalent; Nunito is the closest
// freely-licensed substitute and is bundled in ../fonts so the port stays
// self-contained. Nunito ships as a single variable font (weight axis).
// Instantiate once near the shell root.
Item {
    visible: false
    width: 0
    height: 0

    FontLoader { source: Qt.resolvedUrl("../fonts/Nunito.ttf") }
}
