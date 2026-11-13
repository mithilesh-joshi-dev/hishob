import SwiftUI
import SwiftData

struct HistoryView: View {
    @Binding var showingQuickAdd: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    private var groupedByDay: [(day: Date, items: [Expense])] {
        let groups = Dictionary(grouping: expenses) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return groups
            .map { (day: $0.key, items: $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        Group {
            if expenses.isEmpty {
                ContentUnavailableView(
                    "No expenses yet",
                    systemImage: "tray",
                    description: Text("Log your first expense from the Spending tab.")
                )
            } else {
                List {
                    ForEach(groupedByDay, id: \.day) { group in
                        Section {
                            ForEach(group.items) { expense in
                                row(for: expense)
                            }
                            .onDelete { offsets in
                                delete(offsets, in: group.items)
                            }
                        } header: {
                            HStack {
                                Text(group.day, format: .dateTime.weekday(.wide).day().month())
                                Spacer()
                                Text(Currency.format(group.items.reduce(Decimal(0)) { $0 + $1.amount }))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
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
    }

    private func row(for expense: Expense) -> some View {
        HStack(spacing: 12) {
            Text(expense.category?.emoji ?? "❓")
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category?.name ?? "Uncategorized")
                    .font(.subheadline.weight(.medium))
                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Currency.format(expense.amount))
                    .font(.subheadline.weight(.semibold))
                Text(expense.date, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func delete(_ offsets: IndexSet, in items: [Expense]) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
        AppModel.shared.refreshWidgetSummary()
    }
}
