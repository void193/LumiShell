import QtQuick
import Quickshell
import Lumi.Config
import qs.services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        Privacy;

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
