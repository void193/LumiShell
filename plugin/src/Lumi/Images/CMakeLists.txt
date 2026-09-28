qml_module(lumi-images
    URI Lumi.Images
    SOURCES
        cachingimageprovider.cpp
        imagecacher.cpp
        imageanalyser.cpp
        iutils.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
)
