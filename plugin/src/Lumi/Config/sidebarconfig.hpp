#pragma once

#include "common.hpp"
#include "settings/objectnode.hpp"

namespace lumi::config {

class SidebarConfig : public settings::ObjectNode {
    CONFIG_NODE(SidebarConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(int, minHoverThreshold, 200)
    CONFIG_PROPERTY(int, dragThreshold, 80)
};

} // namespace lumi::config
