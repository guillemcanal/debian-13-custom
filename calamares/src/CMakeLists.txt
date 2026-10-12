# Calamares modules written in C++, built out of the Calamares tree like those
# of https://github.com/calamares/calamares-extensions
cmake_minimum_required(VERSION 3.16 FATAL_ERROR)
project(standard-calamares-modules LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Calamares CONFIG REQUIRED)
# Calamares links to it without finding it itself, calamares-extensions does the same.
find_package(KF6CoreAddons REQUIRED)

# For calamares_add_test()
find_package(ECM REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
find_package(Qt6 REQUIRED COMPONENTS Test)
include(CTest)
include(ECMAddTests)
include(CalamaresAddTest)

set(LIST_SKIPPED_MODULES "")
calamares_add_module_subdirectory(tpm2-state LIST_SKIPPED_MODULES)
calamares_explain_skipped_modules(${LIST_SKIPPED_MODULES})
