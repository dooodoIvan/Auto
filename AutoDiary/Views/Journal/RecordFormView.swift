import SwiftUI
import SwiftData

struct RecordFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let car: Car
    let record: ServiceRecord?

    @State private var title: String
    @State private var category: ServiceCategory
    @State private var date: Date
    @State private var mileage: Int
    @State private var workshop: String
    @State private var laborCost: Double
    @State private var notes: String
    @State private var parts: [PartDraft]

    init(car: Car, record: ServiceRecord?) {
        self.car = car
        self.record = record
        _title = State(initialValue: record?.title ?? "")
        _category = State(initialValue: record?.category ?? .maintenance)
        _date = State(initialValue: record?.date ?? .now)
        _mileage = State(initialValue: record?.mileage ?? car.mileage)
        _workshop = State(initialValue: record?.workshop ?? "")
        _laborCost = State(initialValue: record?.laborCost ?? 0)
        _notes = State(initialValue: record?.notes ?? "")
        _parts = State(initialValue: record?.sortedParts.map(PartDraft.init) ?? [])
    }

    private var partsTotal: Double {
        parts.reduce(0) { $0 + $1.quantity * $1.price }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Что сделано", text: $title)
                    Picker("Категория", selection: $category) {
                        ForEach(ServiceCategory.allCases) { category in
                            Label(category.title, systemImage: category.symbol).tag(category)
                        }
                    }
                    DatePicker("Дата", selection: $date, in: ...Date.now, displayedComponents: .date)
                    LabeledContent("Пробег, км") {
                        NumberField("0", value: $mileage)
                    }
                }

                Section("Работы") {
                    TextField("Сервис или мастер", text: $workshop)
                    LabeledContent("Стоимость работ") {
                        DecimalField("0", value: $laborCost)
                    }
                }

                Section {
                    ForEach($parts) { $part in
                        PartEditorRow(part: $part)
                    }
                    .onDelete { parts.remove(atOffsets: $0) }

                    Button("Добавить запчасть", systemImage: "plus.circle.fill") {
                        parts.append(PartDraft())
                    }
                } header: {
                    Text("Запчасти и материалы")
                } footer: {
                    if !parts.isEmpty {
                        Text("Запчасти на \(Fmt.money(partsTotal)). Смахните влево, чтобы удалить позицию.")
                    }
                }

                Section("Заметки") {
                    TextField("Комментарий", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    LabeledContent {
                        Text(Fmt.money(laborCost + partsTotal))
                            .bold()
                            .monospacedDigit()
                    } label: {
                        Text("Итого").bold()
                    }
                }
            }
            .navigationTitle(record == nil ? "Новая запись" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .disabled(title.trimmed.isEmpty)
                }
            }
        }
    }

    private func save() {
        let target: ServiceRecord
        if let record {
            target = record
        } else {
            target = ServiceRecord()
            context.insert(target)
            target.car = car
        }

        target.title = title.trimmed
        target.category = category
        target.date = date
        target.mileage = mileage
        target.workshop = workshop.trimmed
        target.laborCost = laborCost
        target.notes = notes.trimmed

        // Запчасти проще пересоздать, чем сопоставлять изменения
        let oldParts = target.parts
        target.parts = []
        oldParts.forEach(context.delete)
        for (index, draft) in parts.enumerated() where !draft.isEmpty {
            let part = Part(
                name: draft.name.trimmed,
                number: draft.number.trimmed,
                quantity: draft.quantity,
                price: draft.price,
                sortIndex: index
            )
            context.insert(part)
            part.record = target
        }

        car.registerMileage(mileage)
        dismiss()
    }
}

private struct PartDraft: Identifiable {
    let id = UUID()
    var name = ""
    var number = ""
    var quantity: Double = 1
    var price: Double = 0

    init() {}

    init(_ part: Part) {
        name = part.name
        number = part.number
        quantity = part.quantity
        price = part.price
    }

    var isEmpty: Bool {
        name.trimmed.isEmpty && price == 0
    }
}

private struct PartEditorRow: View {
    @Binding var part: PartDraft

    var body: some View {
        VStack(spacing: 8) {
            TextField("Наименование", text: $part.name)
            HStack(spacing: 8) {
                TextField("Артикул", text: $part.number)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                DecimalField("Кол-во", value: $part.quantity)
                    .frame(width: 56)
                Text("×")
                    .foregroundStyle(.secondary)
                DecimalField("Цена", value: $part.price)
                    .frame(width: 88)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}
