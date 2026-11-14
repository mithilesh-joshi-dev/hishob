import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var showingQuickAdd: Bool
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    private var calendar: Calendar { .current }

    private var todayTotal: Decimal {
        total(for: calendar.dateInterval(of: .day, for: .now))
    }
    private var weekTotal: Decimal {
        total(for: calendar.dateInterval(of: .weekOfYear, for: .now))
    }
    private var monthTotal: Decimal {
        total(for: calendar.dateInterval(of: .month, for: .now))
    }

    private func total(for interval: DateInterval?) -> Decimal {
        guard let interval else { return 0 }
        return expenses
            .filter { interval.contains($0.date) }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Daily totals for the last 7 days (oldest first).
    private var last7Days: [(day: Date, total: Decimal)] {
        (0..<7).compactMap { offset -> (Date, Decimal)? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)) else { return nil }
            let interval = calendar.dateInterval(of: .day, for: day)
            return (day, total(for: interval))
        }
        .reversed()
    }

    /// This month's spend grouped by category, largest first.
    private var monthByCategory: [(name: String, emoji: String, colorHex: String, total: Decimal)] {
        guard let interval = calendar.dateInterval(of: .month, for: .now) else { return [] }
        let monthExpenses = expenses.filter { interval.contains($0.date) }
        var buckets: [String: (emoji: String, colorHex: String, total: Decimal)] = [:]
        for expense in monthExpenses {
            let name = expense.category?.name ?? "Uncategorized"
            let emoji = expense.category?.emoji ?? "❓"
            let colorHex = expense.category?.colorHex ?? "8E8E93"
            var bucket = buckets[name] ?? (emoji, colorHex, 0)
            bucket.total += expense.amount
            buckets[name] = bucket
        }
        return buckets
            .map { (name: $0.key, emoji: $0.value.emoji, colorHex: $0.value.colorHex, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                weekStrip
                if monthlyBudget > 0 {
                    budgetLine
                }
                categorySection
            }
            .padding(20)
            .padding(.bottom, 80)
        }
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .bottomTrailing) {
            logButton
                .padding(.trailing, 24)
                .padding(.bottom, 12)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Spent today")
                .font(.title3.weight(.medium))
            Text(Currency.format(todayTotal))
                .font(.money(54))
                .foregroundStyle(Theme.brand)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())

            HStack(spacing: 24) {
                stat("This week", weekTotal)
                stat("This month", monthTotal)
            }
            .padding(.top, 8)
        }
    }

    private func stat(_ label: String, _ value: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Currency.format(value))
                .font(.money(18))
        }
    }

    private var weekStrip: some View {
        let maxTotal = last7Days.map(\.total).max() ?? 0
        return HStack(alignment: .bottom, spacing: 12) {
            ForEach(last7Days, id: \.day) { item in
                let isToday = calendar.isDateInToday(item.day)
                let fraction = maxTotal > 0
                    ? NSDecimalNumber(decimal: item.total).doubleValue / NSDecimalNumber(decimal: maxTotal).doubleValue
                    : 0
                VStack(spacing: 6) {
                    Capsule()
                        .fill(isToday ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Color(.systemFill)))
                        .frame(width: 10, height: max(6, 64 * fraction))
                        .frame(maxHeight: 64, alignment: .bottom)
                    Text(item.day, format: .dateTime.weekday(.narrow))
                        .font(.caption2.weight(isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? Theme.brand : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 84, alignment: .bottom)
    }

    private var budgetLine: some View {
        let spent = NSDecimalNumber(decimal: monthTotal).doubleValue
        let fraction = monthlyBudget > 0 ? min(spent / monthlyBudget, 1) : 0
        let isOver = spent > monthlyBudget
        let barColor: Color = isOver ? Theme.over : fraction > 0.8 ? Theme.warning : Theme.brand
        return VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: fraction)
                .tint(barColor)
            Text(isOver
                 ? "Over budget by \(Currency.format(monthTotal - Decimal(monthlyBudget)))"
                 : "\(Currency.format(Decimal(monthlyBudget) - monthTotal)) left this month")
                .font(.caption)
                .foregroundStyle(isOver ? Theme.over : .secondary)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Where it went")
                .font(.title3.weight(.semibold))
            if monthByCategory.isEmpty {
                Text("Nothing logged this month. Tap the green button to add your first expense.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let monthMax = monthByCategory.first?.total ?? 1
                ForEach(monthByCategory, id: \.name) { item in
                    categoryRow(item, monthMax: monthMax)
                }
            }
        }
    }

    private func categoryRow(
        _ item: (name: String, emoji: String, colorHex: String, total: Decimal),
        monthMax: Decimal
    ) -> some View {
        let color = Color(hex: item.colorHex)
        let share = NSDecimalNumber(decimal: item.total).doubleValue
            / max(NSDecimalNumber(decimal: monthMax).doubleValue, 0.01)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Text(item.emoji)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(Currency.format(item.total))
                        .font(.money(15))
                }
                ProgressView(value: share)
                    .tint(color)
                    .scaleEffect(x: 1, y: 0.7, anchor: .center)
            }
        }
    }

    private var logButton: some View {
        Button {
            showingQuickAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Theme.brandGradient, in: Circle())
                .shadow(color: Theme.brand.opacity(0.35), radius: 10, y: 5)
        }
        .accessibilityLabel("Log expense")
    }
}
