// UI of the tpm2-state module: tells whether the TPM2 can unlock the encrypted disk,
// and offers to clear it when a previous OS owns it.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Tpm2State


Rectangle {
    id: page
    SystemPalette { id: system }
    color: system.window

    // The module's Config object. Calamares gives it as a context property, unknown
    // to the linter: this is the only place that reads it.
    readonly property Config conf: config // qmllint disable unqualified

    // Outcome of the last click on the clear button
    property bool cleared: false
    property bool failed: false

    // Whole sentences only, for the translations of lang/.
    readonly property string owned: qsTr("The TPM2 module of this computer is locked by a previously installed system: it cannot receive the key of the encrypted disk.")
    readonly property string consequences: qsTr("<b>Clearing destroys all the keys the module holds</b>: another system on this computer, for instance Windows with BitLocker, will ask for its recovery key.")
    readonly property string withoutClearing: qsTr("Without clearing, you will have to type the passphrase of the encrypted disk at each boot.")
    readonly property var messages: ({
        "usable": [qsTr("The TPM2 module of this computer will unlock the encrypted disk automatically at each boot.")],
        "absent": [qsTr("No usable TPM2 module was found on this computer: you will have to type the passphrase of the encrypted disk at each boot."),
                   qsTr("If the module is only disabled, enable it in the BIOS/UEFI setup, then start the installation again.")],
        "clearable": [owned,
                      qsTr("The installer can clear it now.") + " " + consequences,
                      withoutClearing],
        "ppi": [owned,
                qsTr("The installer can ask the firmware to clear it: this will happen at the next reboot, after you confirm on screen.") + " " + consequences,
                withoutClearing],
        "requested": [qsTr("A request to clear the TPM2 module has been filed with the firmware (ppi/request)."),
                      qsTr("Reboot the computer and confirm the clearing when the firmware asks for it, then start the installation again.")],
        "locked": [owned + " " + qsTr("The installer cannot clear it."),
                   qsTr("To use it, clear it yourself: reboot, enter the BIOS/UEFI setup (F2, F10, Del or Esc key depending on the manufacturer) and look in the Security menu for the “Clear TPM” or “Reset TPM” option. Then start the installation again."),
                   consequences,
                   withoutClearing]
    })

    function clear() {
        var before = conf.state
        conf.clear()
        cleared = before === "clearable" && conf.state === "usable"
        failed = conf.state === before
    }

    // Called by Calamares each time the page is shown.
    function onActivate() {
        cleared = false
        failed = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        Label {
            Layout.fillWidth: true
            text: qsTr("Unlocking the encrypted disk with the TPM2 module")
            font.bold: true
            font.pointSize: 14
            wrapMode: Text.WordWrap
        }
        Label {
            Layout.fillWidth: true
            visible: page.cleared
            text: qsTr("The TPM2 module has been cleared.")
        }
        Label {
            Layout.fillWidth: true
            visible: page.failed
            color: "#c0392b"
            text: qsTr("Clearing the TPM2 module failed.")
        }
        Repeater {
            model: page.messages[page.conf.state] || []
            Label {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                textFormat: Text.StyledText
                wrapMode: Text.WordWrap
            }
        }
        Button {
            visible: page.conf.state === "clearable" || page.conf.state === "ppi"
            text: page.conf.state === "ppi" ? qsTr("Ask to clear the TPM2 module") : qsTr("Clear the TPM2 module")
            onClicked: page.clear()
        }
        Button {
            visible: page.conf.state === "requested"
            text: qsTr("Reboot")
            onClicked: page.conf.reboot()
        }
        Item { Layout.fillHeight: true }
    }
}
