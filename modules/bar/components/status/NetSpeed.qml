import QtQuick
import QtQuick.Layouts
import Lumi.Components
import Lumi.Config
import Lumi.Services
import qs.components
import qs.services

// Live down/up rate in two compact mono lines, e.g. "↓1.2M" over "↑30K"
ColumnLayout {
    id: root

    required property color colour

    function compact(bytes: real): string {
        if (!(bytes > 0) || !isFinite(bytes))
            return "0";
        const units = ["", "K", "M", "G"];
        let i = 0;
        while (bytes >= 1000 && i < units.length - 1) {
            bytes /= 1024;
            i++;
        }
        return (bytes < 10 && i > 0 ? bytes.toFixed(1) : Math.round(bytes).toString()) + units[i];
    }

    spacing: -2

    ServiceRef {
        service: NetworkUsage
    }

    Rate {
        arrow: "↓"
        rate: NetworkUsage.downloadSpeed
        textColour: root.colour
    }

    Rate {
        arrow: "↑"
        rate: NetworkUsage.uploadSpeed
        textColour: Colours.palette.m3outline
    }

    component Rate: StyledText {
        required property string arrow
        required property real rate
        required property color textColour

        Layout.alignment: Qt.AlignHCenter
        text: arrow + root.compact(rate)
        color: textColour
        font: Tokens.font.mono.builders.small.size(9).build()
    }
}
