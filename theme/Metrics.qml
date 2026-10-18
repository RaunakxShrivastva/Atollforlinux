pragma Singleton
import QtQuick

// Corner-radius scale + spacing, mirroring Atoll's SwiftUI values.
// Radii observed: 2, 4, 6, 8, 10, 12, 14, 16, 18, 30.
QtObject {
    readonly property int r2: 2
    readonly property int r4: 4
    readonly property int r6: 6
    readonly property int r8: 8
    readonly property int r10: 10
    readonly property int r12: 12
    readonly property int r14: 14
    readonly property int r16: 16
    readonly property int r18: 18
    readonly property int r30: 30

    readonly property int gapXs: 4
    readonly property int gapS: 6
    readonly property int gapM: 8
    readonly property int gapL: 12
    readonly property int gapXl: 16

    readonly property int padCard: 12
    readonly property int hairline: 1
}
