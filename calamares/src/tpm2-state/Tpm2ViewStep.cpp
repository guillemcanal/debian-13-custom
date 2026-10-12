#include "Tpm2ViewStep.h"

#include "utils/Retranslator.h"

#include <QCoreApplication>
#include <QQmlEngine>

Tpm2ViewStep::Tpm2ViewStep( QObject* parent )
    : Calamares::QmlViewStep( parent )
{
    connect( &m_config, &Config::stateChanged, this, [ this ] { emit nextStatusChanged( isNextEnabled() ); } );

    QCoreApplication::installTranslator( &m_translator );
    CALAMARES_RETRANSLATE(
        // Loading sends a language change too: only load when Calamares' language changed.
        const auto language = Calamares::translatorLocaleName();
        if ( language.name != m_language )
        {
            m_language = language.name;
            Calamares::loadTranslator( language, QStringLiteral( "tpm2-state_" ), &m_translator );
        }
        // Calamares does not re-evaluate the translations of its QML pages. The
        // engine, private to QmlViewStep, is a child of the step.
        if ( auto* engine = findChild< QQmlEngine* >() )
        {
            engine->retranslate();
        }
    );
}

QString
Tpm2ViewStep::prettyName() const
{
    return QStringLiteral( "TPM2" );
}

bool
Tpm2ViewStep::isNextEnabled() const
{
    // A clear request only takes effect at reboot: nothing to go on with.
    return m_config.state() != QLatin1String( "requested" );
}

void
Tpm2ViewStep::onActivate()
{
    m_config.refresh();
    Calamares::QmlViewStep::onActivate();
}

CALAMARES_PLUGIN_FACTORY_DEFINITION( Tpm2ViewStepFactory, registerPlugin< Tpm2ViewStep >(); )
