pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// LLM usage backend for the "Usage" tab, standing in for Atoll's
// managers/LLMUsage (LLMUsageManager + the provider/quota clients).
//
// Atoll fetches each provider in-process: Claude/Codex stream their local JSONL
// logs and price them against pricing.json, and quota clients hit the provider
// APIs. Streaming tens of megabytes and pricing it is not something a QML view
// should do, so the work lives in bin/atoll-llmusage and this service just runs
// it and holds the parsed result.
//
// `results` is keyed by provider id (UsageResult shape): { status, reason } for
// a failure and the UsageSnapshot fields for a success. Providers whose data
// sources are macOS-only report a failure reason the view renders, which is the
// same card Atoll shows for a detected-but-unconfigured provider.
QtObject {
    id: root

    // Results by provider id. Reassigned whole so bindings re-evaluate.
    property var results: ({})

    property bool busy: false
    property var generated: 0

    // Atoll's LLMUsageManager.minRefreshInterval: a tab open must not spawn a
    // scan more than once a minute.
    readonly property int minRefreshInterval: 60
    property double lastRefresh: 0

    readonly property string helper:
        String(Quickshell.shellDir).replace(/^file:\/\//, "") + "/bin/atoll-llmusage"

    // Refresh the given providers. `force` bypasses the debounce (the settings
    // toggle path uses it, like refreshAll(force: true)).
    function refreshAll(providers, force) {
        var list = providers && providers.length ? providers : Settings.llmEnabledProviders;
        if (list.length === 0) {
            root.results = ({});
            return;
        }
        if (root.busy) return;
        var now = Date.now() / 1000;
        if (!force && root.lastRefresh > 0 && now - root.lastRefresh < root.minRefreshInterval)
            return;
        root.lastRefresh = now;
        root.busy = true;

        // Drop disabled providers' stale results (LLMUsageManager does the same),
        // then mark the fresh set loading.
        var next = {};
        for (var i = 0; i < list.length; i++) {
            var id = list[i];
            next[id] = root.results[id] !== undefined ? root.results[id] : { status: "loading" };
        }
        root.results = next;

        var cmd = [root.helper];
        for (var j = 0; j < list.length; j++) cmd.push(list[j]);
        collect.command = cmd;
        collect.running = true;
    }

    property Process collect: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var doc = JSON.parse(this.text);
                    if (doc && doc.providers) {
                        root.results = doc.providers;
                        root.generated = doc.generated || 0;
                    }
                } catch (e) {
                    // Keep the loading state; the view shows it as still loading
                    // rather than an invented failure.
                }
            }
        }
        onExited: root.busy = false
    }

    // Snapshot accessors so the view stays free of undefined-guards.
    function resultFor(id) {
        var r = root.results[id];
        return r === undefined ? { status: "loading" } : r;
    }

    function statusOf(id) {
        return root.resultFor(id).status;
    }
}
