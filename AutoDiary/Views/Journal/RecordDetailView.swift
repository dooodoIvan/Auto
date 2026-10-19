import SwiftUI
import SwiftData

struct RecordDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let record: ServiceRecord

    @State private var showingEdit = false
    @State private var confirmingDelete = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    CategoryIcon(category: record.category, size: 48)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.title)
                            .font(.title3.bold())
                        Text(record.category.title)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                LabeledContent("Дата", value: Fmt.date(record.date))
                LabeledContent("Пробег", value: Fmt.km(record.mileage))
                if !record.workshop.isEmpty {
                    LabeledContent("Сервис", value: record.workshop)
                }
            }

            if !record.parts.isEmpty {
                Section("Запчасти и материалы") {
                    ForEach(record.sortedParts) { part in
                        PartRow(part: part)
                    }
                }
            }

            Section("Стоимость") {
                LabeledContent("Работы", value: Fmt.money(record.laborCost))
                LabeledContent("Запчасти", value: Fmt.money(record.partsCost))
                LabeledContent {
                    Text(Fmt.money(record.totalCost)).bold()
                } label: {
                    Text("Итого").bold()
                }
            }

            if !record.notes.isEmpty {
                Section("Заметки") {
                    Text(record.notes)
                }
            }

            Section {
                Button("Удалить запись", role: .destructive) { confirmingDelete = true }
            }
        }
        .navigationTitle(record.category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Изменить") { showingEdit = true }
        }
        .sheet(isPresented: $showingEdit) {
            if let car = record.car {
                RecordFormView(car: car, record: record)
            }
        }
        .confirmationDialog("Удалить запись?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                context.delete(record)
                dismiss()
            }
        }
    }
}

private struct PartRow: View {
    let part: Part

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(part.name)
                Spacer()
                Text(Fmt.money(part.total))
                    .monospacedDigit()
            }
            Text(details)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var details: String {
        let amount = "\(Fmt.number(part.quantity)) × \(Fmt.money(part.price))"
        return part.number.isEmpty ? amount : "\(part.number) · \(amount)"
    }
}
