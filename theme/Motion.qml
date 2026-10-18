pragma Singleton
import QtQuick

// Motion tokens. Atoll's dominant curves are SwiftUI .smooth(duration: 0.18-0.4)
// and .spring(response: 0.3, dampingFraction: 0.9) -- near critical damping,
// essentially no overshoot. "smoothCurve" approximates .smooth.
QtObject {
    readonly property int instant: 120
    readonly property int fast: 180
    readonly property int base: 250
    readonly property int slow: 320

    // cubic-bezier(0.32, 0.72, 0, 1)
    readonly property var smoothCurve: [0.32, 0.72, 0.0, 1.0]
    readonly property var exitCurve: [0.4, 0.0, 1.0, 1.0]

    // Notch open/close morph.
    // Atoll drives the shape and its content from ONE SwiftUI animation
    // transaction, so width/height/radii/content move in lockstep and can be
    // interrupted mid-flight from the current velocity. We reproduce that with
    // a real spring integrator (components/Spring.qml); these are the SwiftUI
    // pairs Atoll picks per presentation (animations/drop.swift):
    //   notch  -> Animation.spring(.bouncy(duration: 0.4))
    //             .bouncy(duration) == .spring(duration:, extraBounce: 0.15)
    //             -> response 0.4, zeta 0.85 (a small, deliberate bounce)
    //   island -> Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.7)
    //             -> expo-out, no overshoot ~= critically damped (zeta 1.0)
    readonly property real morphResponseNotch: 0.4
    readonly property real morphDampingNotch: 0.85
    readonly property real morphResponseIsland: 0.5
    readonly property real morphDampingIsland: 1.0
    // Content lives in the same spring as the shape -> keep these equal to the
    // morph values (per presentation) so nothing arrives early/late.
    readonly property real contentResponse: 0.34
    readonly property real contentDamping: 0.88

    readonly property int atollOpenDuration: 700
    readonly property var atollOpenCurve: [0.16, 1.0, 0.3, 1.0]
    readonly property int contentSpringResponse: 340
    readonly property real contentSpringDamping: 0.88

    // Spring: response 0.3s, damping 0.9
    readonly property real springMass: 1.0
    readonly property real springStiffness: 3.4
    readonly property real springDamping: 0.9
}
