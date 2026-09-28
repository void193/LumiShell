#include "common.hpp"

#include <qstandardpaths.h>

namespace lumi::config {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcConfig, "lumi.config", QtInfoMsg)

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/lumi"_s;
}

QString monitorConfigDir() {
    return configDir() + u"/monitors"_s;
}

} // namespace lumi::config
