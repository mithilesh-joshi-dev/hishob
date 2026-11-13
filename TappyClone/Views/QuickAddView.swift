import SwiftUI
import SwiftData

struct QuickAddView: View {
    /// When set, the view edits this expense instead of creating a new one.
    var expenseToEdit: Expense?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @State private var amountText = ""
    @State private var note = ""
    @State private var selectedCategory: ExpenseCategory?

    private var amount: Decimal? {
        guard !amountText.isEmpty else { return nil }
        return Decimal(string: amountText)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer(minLength: 8)

                Text(amountDisplay)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(amount == nil ? .secondary : .primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)

                categoryPicker

                TextField("Add a note (optional)", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                keypad

                Button(action: save) {
                    Text(expenseToEdit == nil ? "Log Expense" : "Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(amount == nil || amount == 0)
                .padding(.horizontal)
            }
            .padding(.bottom)
            .navigationTitle(expenseToEdit == nil ? "Quick Add" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if let expenseToEdit {
                amountText = "\(expenseToEdit.amount)"
                note = expenseToEdit.note
                selectedCategory = expenseToEdit.category
            } else if selectedCategory == nil {
                selectedCategory = categories.first
            }
        }
    }

    private var amountDisplay: String {
        if let amount { return Currency.format(amount) }
        return Currency.format(0)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    let isSelected = selectedCategory?.persistentModelID == category.persistentModelID
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 4) {
                            Text(category.emoji)
                            Text(category.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                isSelected
                                    ? Color(hex: category.colorHex).opacity(0.25)
                                    : Color(.secondarySystemBackground)
                            )
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                isSelected ? Color(hex: category.colorHex) : .clear,
                                lineWidth: 1.5
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var keypad: some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
            ForEach(keys, id: \.self) { key in
                Button {
                    tap(key)
                } label: {
                    Text(key)
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private func tap(_ key: String) {
        switch key {
        case "⌫":
            if !amountText.isEmpty { amountText.removeLast() }
        case ".":
            if !amountText.contains(".") {
                amountText += amountText.isEmpty ? "0." : "."
            }
        default:
            let decimals = amountText.split(separator: ".")
            if decimals.count == 2 && decimals[1].count >= 2 { return }
            if amountText.count < 10 { amountText += key }
        }
    }

    private func save() {
        guard let amount, amount > 0 else { return }
        if let expenseToEdit {
            expenseToEdit.amount = amount
            expenseToEdit.note = note.trimmingCharacters(in: .whitespaces)
            expenseToEdit.category = selectedCategory
        } else {
            let expense = Expense(
                amount: amount,
                note: note.trimmingCharacters(in: .whitespaces),
                category: selectedCategory
            )
            modelContext.insert(expense)
        }
        try? modelContext.save()
        AppModel.shared.refreshWidgetSummary()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}

#Preview {
    QuickAddView()
        .modelContainer(AppModel.shared.container)
}
