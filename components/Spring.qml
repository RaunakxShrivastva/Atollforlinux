import QtQuick

// SwiftUI-style spring for a single scalar.
//
// Qt's own animators interpolate a fixed curve from the current value with zero
// velocity, so an interrupted animation restarts flat. SwiftUI (what Atoll uses)
// integrates a spring: interrupting retargets from the *current velocity*, which
// is what makes the island morph feel continuous when you hover in and out fast.
//
// Parameters mirror SwiftUI exactly: `response` is the period in seconds and
// `dampingFraction` is zeta (1.0 = critically damped, no overshoot; 0.82 = a
// slight, Atoll-like bounce).
//
// Semi-implicit Euler is unconditionally stable here because dt is clamped to
// 32 ms (a dropped frame can never make the integrator blow up).
QtObject {
    id: root

    property real target: 0

    // Animated state. Read `value`; write `target`.
    property real value: 0
    property real velocity: 0

    property real response: 0.4
    property real dampingFraction: 0.85
    // Settle thresholds: value within `epsilon` of target (in target units).
    property real epsilon: 0.001
    property bool running: false

    // omega0 = 2*pi/response;  k = omega0^2  (mass = 1);  c = 2*zeta*omega0
    readonly property real stiffness: Math.pow(2 * Math.PI / response, 2)
    readonly property real damping: 2 * dampingFraction * (2 * Math.PI / response)

    // Jump without animating (first layout, tab resets, tests).
    function snap(v) {
        running = false;
        value = v;
        velocity = 0;
    }

    onTargetChanged: {
        if (Math.abs(value - target) > epsilon || Math.abs(velocity) > epsilon)
            running = true;
    }

    Component.onCompleted: {
        if (Math.abs(value - target) > epsilon)
            running = true;
    }

    // QtObject has no default property, so the ticker is declared as a
    // property value (QML parents it to `root`).
    //
    // NOTE: FrameAnimation.triggered() carries NO arguments -- the timing lives
    // on the object as `frameTime` / `smoothFrameTime` (seconds). Reading a
    // signal argument here yields undefined and poisons the integrator with NaN,
    // which blanks every geometry bound to `value`. Never do that.
    property FrameAnimation ticker: FrameAnimation {
        running: root.running
        onTriggered: {
            if (!isFinite(root.value) || !isFinite(root.velocity)) {
                root.snap(root.target);
                return;
            }
            let dt = ticker.smoothFrameTime;
            if (!(dt > 0))
                dt = ticker.frameTime;
            if (!(dt > 0))
                dt = 1 / 60;
            if (dt > 0.032)
                dt = 0.032;
            const a = -root.stiffness * (root.value - root.target) - root.damping * root.velocity;
            root.velocity += a * dt;
            root.value += root.velocity * dt;
            if (Math.abs(root.value - root.target) <= root.epsilon
                    && Math.abs(root.velocity) <= root.epsilon) {
                root.value = root.target;
                root.velocity = 0;
                root.running = false;
            }
        }
    }
}
