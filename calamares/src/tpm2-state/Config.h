#ifndef TPM2_CONFIG_H
#define TPM2_CONFIG_H

#include <QObject>
#include <QtQml/qqmlregistration.h>

/** @brief Whether the TPM2 can unlock the encrypted disk, and its actions, for the QML
 *
 * The state is one of:
 *  - usable     systemd-cryptenroll can seal the disk key in the TPM2
 *  - absent     no TPM2 that answers
 *  - clearable  a previous OS owns the TPM2, `tpm2 clear` is allowed
 *  - ppi        a previous OS owns the TPM2, the firmware accepts a clear request
 *  - requested  a clear request is pending, the firmware runs it at next boot
 *  - locked     a previous OS owns the TPM2, only the firmware setup can clear it
 *
 * It is also the "tpm2State" of global storage, for the tpm2-enroll job.
 */
class Config : public QObject
{
    Q_OBJECT
    // Only names the type for tpm2-state.qml: the step owns the one object.
    QML_ELEMENT
    QML_UNCREATABLE( "" )
    Q_PROPERTY( QString state READ state NOTIFY stateChanged FINAL )

public:
    QString state() const { return m_state; }

    /// @brief The state, from the outputs of `tpm2 getcap` and the files of the firmware's interface
    static QString decide( const QString& flags,
                           const QString& handles,
                           const QString& ppiRequest,
                           const QString& ppiOperations );

public Q_SLOTS:
    void refresh();
    /// @brief Clears the TPM2 (clearable) or asks the firmware to (ppi)
    void clear();
    /// @brief Reboots, for the firmware to run the request
    void reboot();

signals:
    void stateChanged( const QString& state );

private:
    QString m_state;
};

#endif
