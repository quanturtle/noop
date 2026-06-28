import WidgetKit
import SwiftUI
import StrandDesign

struct NOOPMacEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct NOOPMacProvider: TimelineProvider {
    func placeholder(in context: Context) -> NOOPMacEntry {
        NOOPMacEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (NOOPMacEntry) -> Void) {
        completion(NOOPMacEntry(date: Date(), snapshot: WidgetSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NOOPMacEntry>) -> Void) {
        let snap = WidgetSnapshot.load() ?? .placeholder
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [NOOPMacEntry(date: Date(), snapshot: snap)], policy: .after(next)))
    }
}

struct NOOPMacWidgetView: View {
    let entry: NOOPMacEntry

    private var snap: WidgetSnapshot { entry.snapshot }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            statCell("Charge", value: snap.recovery.map { "\($0)%" }, tint: chargeColor)
            statCell("Effort", value: snap.effort.map(String.init), tint: effortColor)
            statCell("Rest", value: snap.rest.map { "\($0)%" }, tint: restColor)
        }
        .padding(16)
    }

    private var chargeColor: Color {
        guard let r = snap.recovery else { return StrandPalette.textTertiary }
        return StrandPalette.recoveryColor(Double(r))
    }

    /// Effort is on the 0–100 axis (`StrainScorer.maxStrain == 100`), so the fraction is value / 100.
    private var effortColor: Color {
        guard let e = snap.effort else { return StrandPalette.textTertiary }
        return StrandPalette.effortTint(fraction: Double(e) / 100)
    }

    private var restColor: Color {
        guard let r = snap.rest else { return StrandPalette.textTertiary }
        return StrandPalette.recoveryColor(Double(r))
    }

    private func statCell(_ label: String, value: String?, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value ?? "–")
                .font(StrandFont.number(26))
                .foregroundStyle(value == nil ? StrandPalette.textTertiary : tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label).strandOverline()
        }
        .frame(maxWidth: .infinity)
    }
}

struct NOOPMacWidget: Widget {
    let kind = "NOOPMacWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NOOPMacProvider()) { entry in
            NOOPMacWidgetView(entry: entry)
                .containerBackground(StrandPalette.surfaceBase, for: .widget)
        }
        .configurationDisplayName("NOOP Scores")
        .description("Charge, Effort, and Rest at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct NOOPMacWidgetBundle: WidgetBundle {
    var body: some Widget { NOOPMacWidget() }
}

#if DEBUG
private extension WidgetSnapshot {
    static var empty: WidgetSnapshot {
        WidgetSnapshot(recovery: nil, bpm: nil, batteryPct: nil, bonded: false, updated: Date(),
                       effort: nil, rest: nil)
    }
}

#Preview("Scores — medium", as: .systemMedium) {
    NOOPMacWidget()
} timeline: {
    NOOPMacEntry(date: .now, snapshot: .placeholder)
    NOOPMacEntry(date: .now, snapshot: .empty)
}
#endif
