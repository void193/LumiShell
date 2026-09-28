qml_module(lumi-models
    URI Lumi.Models
    SOURCES
        filesystemmodel.cpp
        appdb.cpp
    LIBRARIES
        Qt::Gui
        Qt::Concurrent
        Qt::Sql
)
