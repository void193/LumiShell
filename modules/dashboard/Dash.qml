import "dash"
import QtQuick.Layouts
import Lumi.Config
import qs.components
import qs.services

GridLayout {
    id: root

    required property ScreenState screenState

    rowSpacing: Tokens.spacing.medium
    columnSpacing: Tokens.spacing.medium

    // Row 0: banner across the full width
    Rect {
        Layout.row: 0
        Layout.column: 0
        Layout.columnSpan: 4
        Layout.fillWidth: true
        Layout.preferredHeight: sys.implicitHeight + Tokens.padding.extraLarge * 2

        radius: Tokens.rounding.extraLarge

        SysCard {
            id: sys
        }
    }

    // Row 1: clock, calendar, exposure readout, resources
    Rect {
        Layout.row: 1
        Layout.column: 0
        Layout.preferredWidth: dateTime.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        DateTime {
            id: dateTime
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.preferredWidth: 300
        Layout.preferredHeight: calendar.implicitHeight

        radius: Tokens.rounding.extraLarge

        Calendar {
            id: calendar

            screenState: root.screenState
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 2
        Layout.preferredWidth: privacy.implicitWidth + Tokens.padding.large * 2
        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge

        PrivacyCard {
            id: privacy
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 3
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        Resources {
            id: resources
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
