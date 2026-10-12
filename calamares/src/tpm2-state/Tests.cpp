#include "Config.h"

#include <QtTest/QtTest>

class Tpm2Tests : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testDecide();
};

void
Tpm2Tests::testDecide()
{
    const QString srk = "- 0x81000001\n";
    const QString owned = "ownerAuthSet: 1\nlockoutAuthSet: 1\ndisableClear: 0\n";
    const QString ppi = "4 0: Not implemented\n5 3: User required\n";

    QCOMPARE( Config::decide( "ownerAuthSet:    0\n", "", "", "" ), "usable" );
    QCOMPARE( Config::decide( owned, srk, "", "" ), "usable" );
    QCOMPARE( Config::decide( "ownerAuthSet: 1\nlockoutAuthSet: 0\ndisableClear: 0\n", "", "", ppi ), "clearable" );
    QCOMPARE( Config::decide( owned, "", "0\n", ppi ), "ppi" );
    QCOMPARE( Config::decide( owned, "", "5 0\n", ppi ), "requested" );
    QCOMPARE( Config::decide( owned, "", "0\n", "5 2: Blocked for OS by BIOS\n" ), "locked" );
    QCOMPARE( Config::decide( owned, "", "", "" ), "locked" );
}

QTEST_GUILESS_MAIN( Tpm2Tests )

#include "Tests.moc"
