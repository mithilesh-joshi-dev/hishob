import WidgetKit
import SwiftUI

struct SpendEntry: TimelineEntry {
    let date: Date
    let summary: SpendSummary?
}

struct SpendProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendEntry {
        SpendEntry(date: .now, summary: SpendSummary(todayTotal: 42.50, todayCount: 3, currencyCode: "USD"))
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendEntry) -> Void) {
        completion(SpendEntry(date: .now, summary: SpendSummary.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendEntry>) -> Void) {
        let entry = SpendEntry(date: .now, summary: SpendSummary.load())
        // Refresh after midnight so "Today" resets even if the app isn't opened.
        let nextMidnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct HishobWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SpendEntry

    private var isStale: Bool {
        guard let summary = entry.summary else { return true }
        return !Calendar.current.isDateInToday(summary.updatedAt)
    }

    private var totalText: String {
        guard let summary = entry.summary else { return "–" }
        return isStale
            ? Decimal(0).formatted(.currency(code: summary.currencyCode))
            : summary.formattedTotal
    }

    private var countText: String {
        guard let summary = entry.summary, !isStale else { return "No expenses yet" }
        return summary.todayCount == 1 ? "1 expense" : "\(summary.todayCount) expenses"
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                Text(totalText)
                    .font(.caption2.weight(.semibold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        case .accessoryInline:
            Text("Spent today: \(totalText)")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's Spending")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(totalText)
                    .font(.headline)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(countText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Today")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.tint)
                }
                Spacer()
                Text(totalText)
                    .font(.title2.weight(.bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(countText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct HishobWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HishobSpendWidget", provider: SpendProvider()) { entry in
            HishobWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "hishob://add"))
        }
        .configurationDisplayName("Today's Spending")
        .description("See today's total and tap to log an expense.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
