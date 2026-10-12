#include "Config.h"

#include "GlobalStorage.h"
#include "JobQueue.h"
#include "utils/System.h"

#include <QFile>
#include <QRegularExpression>

// Where systemd-cryptenroll looks for the storage root key
static const QString SRK = QStringLiteral( "0x81000001" );
// The firmware's TCG Physical Presence Interface, and its operation "Clear"
static const QString PPI = QStringLiteral( "/sys/class/tpm/tpm0/ppi/" );
static const QString PPI_CLEAR = QStringLiteral( "5" );

static Calamares::ProcessResult
run( const QStringList& command )
{
    return Calamares::System::runCommand( command, std::chrono::seconds( 30 ) );
}

static Calamares::ProcessResult
tpm2( const QStringList& arguments )
{
    return run( QStringList { "tpm2" } + arguments + QStringList { "--tcti", "device:/dev/tpmrm0" } );
}

static QString
read( const QString& path )
{
    QFile file( path );
    return file.open( QIODevice::ReadOnly ) ? QString::fromLatin1( file.readAll() ) : QString();
}

QString
Config::decide( const QString& flags,
                const QString& handles,
                const QString& ppiRequest,
                const QString& ppiOperations )
{
    const auto isSet = [ & ]( const QString& flag )
    { return flags.contains( QRegularExpression( flag + QStringLiteral( ":\\s+1" ) ) ); };

    // The owner password is only needed to create the storage root key.
    if ( handles.contains( SRK ) || !isSet( "ownerAuthSet" ) )
    {
        return QStringLiteral( "usable" );
    }
    if ( !isSet( "lockoutAuthSet" ) && !isSet( "disableClear" ) )
    {
        return QStringLiteral( "clearable" );
    }
    if ( ppiRequest.simplified().section( ' ', 0, 0 ) == PPI_CLEAR )
    {
        return QStringLiteral( "requested" );
    }
    // "5 3: User required" or "5 4: User not required"
    if ( ppiOperations.contains(
             QRegularExpression( '^' + PPI_CLEAR + QStringLiteral( " [34]:" ), QRegularExpression::MultilineOption ) ) )
    {
        return QStringLiteral( "ppi" );
    }
    return QStringLiteral( "locked" );
}

void
Config::refresh()
{
    const auto flags = tpm2( { "getcap", "properties-variable" } );
    const auto handles = tpm2( { "getcap", "handles-persistent" } );
    const QString state = flags.getExitCode() || handles.getExitCode()
        ? QStringLiteral( "absent" )
        : decide( flags.getOutput(), handles.getOutput(), read( PPI + "request" ), read( PPI + "tcg_operations" ) );
    if ( state != m_state )
    {
        m_state = state;
        Calamares::JobQueue::instance()->globalStorage()->insert( "tpm2State", m_state );
        emit stateChanged( m_state );
    }
}

void
Config::clear()
{
    if ( m_state == QLatin1String( "clearable" ) )
    {
        tpm2( { "clear" } );
    }
    else if ( m_state == QLatin1String( "ppi" ) )
    {
        QFile request( PPI + "request" );
        if ( request.open( QIODevice::WriteOnly ) )
        {
            request.write( PPI_CLEAR.toLatin1() );
        }
    }
    refresh();
}

void
Config::reboot()
{
    run( { "systemctl", "reboot" } );
}
