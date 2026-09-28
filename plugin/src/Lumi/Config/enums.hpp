#pragma once

#include <qqmlintegration.h>

namespace lumi::config {

#define ENUM(Name, ...)                                                                                                \
    namespace Name {                                                                                                   \
                                                                                                                       \
    Q_NAMESPACE                                                                                                        \
    QML_ELEMENT                                                                                                        \
                                                                                                                       \
    enum Enum {                                                                                                        \
        __VA_ARGS__                                                                                                    \
    };                                                                                                                 \
    Q_ENUM_NS(Enum)                                                                                                    \
                                                                                                                       \
    };

ENUM(BarWorkspaceDisplay, Shapes, Text)
ENUM(BarWorkspaceCapitalisation, Preserve, Upper, Lower)
ENUM(GpuType, Auto, Nvidia, Generic, None)
ENUM(NotifsFullscreen, On, Off)

#undef ENUM

} // namespace lumi::config
