pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int minTemp: 2500
    readonly property int maxTemp: 6500
    readonly property int step: 250
    readonly property int defaultTemp: 4000

    function apply(): void {
        if (props.enabled)
            applyProc.command = ["hyprctl", "hyprsunset", "temperature", String(props.temperature)];
        else
            applyProc.command = ["hyprctl", "hyprsunset", "identity"];
        applyProc.running = true;
    }

    function toggle(): void {
        props.enabled = !props.enabled;
    }

    function enable(): void {
        props.enabled = true;
    }

    function disable(): void {
        props.enabled = false;
    }

    // Lower temperature = warmer/stronger filter. "Increase intensity" moves warmer.
    function increaseIntensity(): void {
        props.temperature = Math.max(root.minTemp, props.temperature - root.step);
        if (!props.enabled)
            props.enabled = true;
        else
            apply();
    }

    function decreaseIntensity(): void {
        props.temperature = Math.min(root.maxTemp, props.temperature + root.step);
        if (props.temperature >= root.maxTemp)
            props.enabled = false;
        else if (props.enabled)
            apply();
    }

    property alias enabled: props.enabled
    property alias temperature: props.temperature

    PersistentProperties {
        id: props

        property bool enabled: false
        property int temperature: root.defaultTemp

        reloadableId: "nightLight"

        onEnabledChanged: root.apply()
        onTemperatureChanged: {
            if (enabled)
                root.apply();
        }
    }

    Process {
        id: applyProc
    }

    Component.onCompleted: apply()

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.enable();
        }

        function disable(): void {
            root.disable();
        }

        function setTemperature(temp: string): void {
            props.temperature = Math.max(root.minTemp, Math.min(root.maxTemp, parseInt(temp)));
        }

        target: "nightlight"
    }
}
