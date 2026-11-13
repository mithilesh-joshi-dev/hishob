import SwiftUI
import SwiftData
import Charts

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
            VStack(spacing: 16) {
                totalsRow
                if monthlyBudget > 0 {
                    budgetCard
                }
                chartCard
                categoryBreakdown
            }
            .padding()
        }
        .navigationTitle("Spending")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingQuickAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showingQuickAdd = true
            } label: {
                Label("Log Expense", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }

    private var totalsRow: some View {
        HStack(spacing: 12) {
            totalCard(title: "Today", value: todayTotal)
            totalCard(title: "This Week", value: weekTotal)
            totalCard(title: "This Month", value: monthTotal)
        }
    }

    private func totalCard(title: String, value: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Currency.format(value))
                .font(.subheadline.weight(.bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var budgetCard: some View {
        let spent = NSDecimalNumber(decimal: monthTotal).doubleValue
        let fraction = monthlyBudget > 0 ? min(spent / monthlyBudget, 1) : 0
        let isOver = spent > monthlyBudget
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Monthly Budget")
                    .font(.headline)
                Spacer()
                Text("\(Currency.format(monthTotal)) / \(Currency.format(Decimal(monthlyBudget)))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isOver ? .red : .secondary)
            }
            ProgressView(value: fraction)
                .tint(isOver ? .red : fraction > 0.8 ? .orange : .green)
            if isOver {
                Text("Over budget by \(Currency.format(monthTotal - Decimal(monthlyBudget)))")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("\(Currency.format(Decimal(monthlyBudget) - monthTotal)) left this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 Days")
                .font(.headline)
            Chart(last7Days, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day, unit: .day),
                    y: .value("Spent", NSDecimalNumber(decimal: item.total).doubleValue)
                )
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Month by Category")
                .font(.headline)
            if monthByCategory.isEmpty {
                Text("No expenses yet. Tap Log Expense to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(monthByCategory, id: \.name) { item in
                    HStack {
                        Text(item.emoji)
                        Text(item.name)
                            .font(.subheadline)
                        Spacer()
                        Text(Currency.format(item.total))
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(hex: item.colorHex).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
