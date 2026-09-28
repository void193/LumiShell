qml_module(lumishell-components
    URI LumiShell.Components
    SOURCES
        lazylistview.cpp
        wavyline.cpp
        buttonrow.cpp
        circularindicatormanager.cpp
        linearindicatormanager.cpp
        sparklineitem.cpp
        visualiserbars.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        lumishell-core
    DEPENDENCIES
        LumiShell
)
