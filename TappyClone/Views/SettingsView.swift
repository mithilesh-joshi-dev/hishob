import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage(Currency.storageKey) private var currencyCode: String = Currency.selectedCode
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var exportURL: URL?
    @State private var exportError = false

    var body: some View {
        Form {
            Section("Currency") {
                Picker("Currency", selection: $currencyCode) {
                    ForEach(Currency.common, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
            }

            Section {
                HStack {
                    Text("Monthly Budget")
                    Spacer()
                    TextField("0", value: $monthlyBudget, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                }
            } header: {
                Text("Budget")
            } footer: {
                Text("Set to 0 to hide the budget card on the Spending tab.")
            }

            Section("Categories") {
                NavigationLink("Manage Categories") {
                    CategoriesView()
                }
            }

            Section("Export") {
                Button("Generate CSV Export") {
                    do {
                        exportURL = try CSVExporter.export(expenses)
                    } catch {
                        exportError = true
                    }
                }
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share tappy-expenses.csv", systemImage: "square.and.arrow.up")
                    }
                }
            }

            Section("Siri & Back Tap") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Log expenses without opening the app:")
                        .font(.subheadline.weight(.medium))
                    Text("• Siri: say \"Log expense in TappyClone\"")
                    Text("• Back Tap: Settings → Accessibility → Touch → Back Tap → pick the \"Log Expense\" shortcut")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
        .alert("Export failed", isPresented: $exportError) {
            Button("OK", role: .cancel) {}
        }
    }
}

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @State private var newName = ""
    @State private var newEmoji = ""

    var body: some View {
        List {
            Section("Add Category") {
                TextField("Name", text: $newName)
                TextField("Emoji", text: $newEmoji)
                Button("Add") {
                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    // The model has no unique constraint (CloudKit compatibility),
                    // so duplicate names are blocked here.
                    guard !categories.contains(where: {
                        $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
                    }) else { return }
                    let category = ExpenseCategory(
                        name: trimmed,
                        emoji: newEmoji.isEmpty ? "🏷️" : String(newEmoji.prefix(2)),
                        colorHex: "5856D6"
                    )
                    modelContext.insert(category)
                    try? modelContext.save()
                    newName = ""
                    newEmoji = ""
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Section("Categories") {
                ForEach(categories) { category in
                    HStack {
                        Text(category.emoji)
                        Text(category.name)
                        Spacer()
                        if category.isDefault {
                            Text("Default")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(categories[index])
                    }
                    try? modelContext.save()
                }
            }
        }
        .navigationTitle("Categories")
    }
}
