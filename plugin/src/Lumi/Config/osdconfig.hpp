#pragma once

#include "common.hpp"
#include "settings/objectnode.hpp"

namespace lumi::config {

class OsdConfig : public settings::ObjectNode {
    CONFIG_NODE(OsdConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, hideDelay, 2000)
    CONFIG_PROPERTY(bool, enableBrightness, true)
    CONFIG_PROPERTY(bool, enableMicrophone, false)
};

} // namespace lumi::config
