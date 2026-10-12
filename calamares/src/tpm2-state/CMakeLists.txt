calamares_add_plugin(tpm2-state
    TYPE viewmodule
    EXPORT_MACRO PLUGINDLLEXPORT_PRO
    SOURCES
        Config.cpp
        Tpm2ViewStep.cpp
    RESOURCES
        tpm2-state.qrc
    SHARED_LIB
)

# The QML module of Config (QML_ELEMENT), imported by tpm2-state.qml. It is compiled
# into the plugin; its description for qmllint and qmlls goes to <build>/Tpm2State.
qt_add_qml_module(${tpm2-state_TARGET}
    URI Tpm2State
    NO_PLUGIN
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Tpm2State
)

calamares_add_test(tpm2statetest SOURCES Tests.cpp Config.cpp)

# Translations of tpm2-state.qml, in lang/ and named like Calamares' own; English is
# in the sources. Calamares::loadTranslator() finds them as
# :/lang/tpm2-state_<language>.qm. After changing a text:
#   lupdate -locations none tpm2-state.qml -ts lang/tpm2-state_fr.ts
qt_add_translations(${tpm2-state_TARGET} TS_FILES lang/tpm2-state_fr.ts RESOURCE_PREFIX /lang)
