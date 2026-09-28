#pragma once

#include <qstandardpaths.h>
#include <qstring.h>

#include "common.hpp"
#include "settings/objectnode.hpp"

namespace lumi::config {

using Qt::StringLiterals::operator""_s;

class UserPaths : public settings::ObjectNode {
    CONFIG_NODE(UserPaths, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(
        QString, wallpaperDir, QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + u"/Wallpapers"_s)
};

} // namespace lumi::config
