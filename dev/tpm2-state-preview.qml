// Dev-only, never part of the ISO: shows the page of the tpm2-state module
// outside Calamares, with a fake `config` whose state is picked in the list.
//   qml -I dev dev/tpm2-state-preview.qml
import QtQuick
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 800
    height: 520

    header: ComboBox {
        id: stateBox
        model: ["usable", "absent", "clearable", "ppi", "requested", "locked"]
    }

    Loader {
        anchors.fill: parent
        source: "../calamares/src/tpm2-state/tpm2-state.qml"
    }
}
