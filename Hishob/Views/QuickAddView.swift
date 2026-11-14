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
        VStack(spacing: 0) {
            header
            Spacer(minLength: 4)
            amountDisplay
            Spacer(minLength: 4)
            categoryPicker
                .padding(.vertical, 14)
            noteField
            keypad
                .padding(.vertical, 16)
            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
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

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .accessibilityLabel("Cancel")
            Spacer()
            if expenseToEdit != nil {
                Text("Edit expense")
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
            Color.clear.frame(width: 34, height: 34)
        }
        .padding(.top, 16)
    }

    private var amountDisplay: some View {
        Text(Currency.format(amount ?? 0))
            .font(.money(58))
            .foregroundStyle(amount == nil ? Color.secondary.opacity(0.45) : Theme.brand)
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.18), value: amountText)
            .frame(maxWidth: .infinity)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories) { category in
                    let isSelected = selectedCategory?.persistentModelID == category.persistentModelID
                    let color = Color(hex: category.colorHex)
                    Button {
                        selectedCategory = category
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        VStack(spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(color.opacity(isSelected ? 0.3 : 0.14))
                                    .frame(width: 48, height: 48)
                                if isSelected {
                                    Circle()
                                        .strokeBorder(color, lineWidth: 2)
                                        .frame(width: 48, height: 48)
                                }
                                Text(category.emoji)
                                    .font(.title3)
                            }
                            Text(category.name)
                                .font(.caption2.weight(isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? .primary : .secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var noteField: some View {
        TextField("Add note", text: $note)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.vertical, 9)
            .background(Color(.secondarySystemBackground), in: Capsule())
    }

    private var keypad: some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(keys, id: \.self) { key in
                Button {
                    tap(key)
                } label: {
                    Text(key)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(key == "⌫" ? .secondary : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 68)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(KeypadButtonStyle())
            }
        }
        .frame(maxWidth: 320)
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(saveTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    amount == nil || amount == 0
                        ? AnyShapeStyle(Color(.systemFill))
                        : AnyShapeStyle(Theme.brandGradient),
                    in: Capsule()
                )
        }
        .disabled(amount == nil || amount == 0)
    }

    private var saveTitle: String {
        if expenseToEdit != nil { return "Save changes" }
        if let amount, amount > 0 { return "Log \(Currency.format(amount))" }
        return "Log expense"
    }

    private func tap(_ key: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

private struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    QuickAddView()
        .modelContainer(AppModel.shared.container)
}
