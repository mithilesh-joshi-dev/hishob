import SwiftUI
import SwiftData

struct HistoryView: View {
    @Binding var showingQuickAdd: Bool
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var editingExpense: Expense?

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
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingExpense = expense }
                            }
                            .onDelete { offsets in
                                delete(offsets, in: group.items)
                            }
                        } header: {
                            HStack {
                                Text(dayTitle(group.day))
                                Spacer()
                                Text(Currency.format(group.items.reduce(Decimal(0)) { $0 + $1.amount }))
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .sheet(item: $editingExpense) { expense in
            QuickAddView(expenseToEdit: expense)
        }
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

    private func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month())
    }

    private func row(for expense: Expense) -> some View {
        let color = Color(hex: expense.category?.colorHex ?? "8E8E93")
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 40, height: 40)
                Text(expense.category?.emoji ?? "❓")
                    .font(.body)
            }
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
                    .font(.money(15))
                Text(expense.date, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func delete(_ offsets: IndexSet, in items: [Expense]) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
        AppModel.shared.refreshWidgetSummary()
    }
}
