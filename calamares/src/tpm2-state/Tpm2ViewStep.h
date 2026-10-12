#ifndef TPM2VIEWSTEP_H
#define TPM2VIEWSTEP_H

#include "Config.h"

#include "DllMacro.h"
#include "utils/PluginFactory.h"
#include "viewpages/QmlViewStep.h"

#include <QTranslator>

/** @brief Tells whether the TPM2 can unlock the encrypted disk
 *
 * Offers to clear it when a previous OS owns it. The UI is tpm2-state.qml.
 */
class PLUGINDLLEXPORT Tpm2ViewStep : public Calamares::QmlViewStep
{
    Q_OBJECT

public:
    explicit Tpm2ViewStep( QObject* parent = nullptr );

    QString prettyName() const override;
    bool isNextEnabled() const override;
    void onActivate() override;
    QObject* getConfig() override { return &m_config; }

private:
    Config m_config;
    QTranslator m_translator;
    QString m_language;
};

CALAMARES_PLUGIN_FACTORY_DECLARATION( Tpm2ViewStepFactory )

#endif
