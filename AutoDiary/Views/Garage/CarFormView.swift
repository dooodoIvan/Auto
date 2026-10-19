import SwiftUI
import SwiftData

struct CarFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedCarID") private var selectedCarID = ""

    let car: Car?

    @State private var name: String
    @State private var make: String
    @State private var modelName: String
    @State private var year: String
    @State private var plate: String
    @State private var vin: String
    @State private var mileage: Int

    init(car: Car?) {
        self.car = car
        _name = State(initialValue: car?.name ?? "")
        _make = State(initialValue: car?.make ?? "")
        _modelName = State(initialValue: car?.modelName ?? "")
        _year = State(initialValue: car?.year.map(String.init) ?? "")
        _plate = State(initialValue: car?.plate ?? "")
        _vin = State(initialValue: car?.vin ?? "")
        _mileage = State(initialValue: car?.mileage ?? 0)
    }

    private var canSave: Bool {
        !(name.trimmed + make.trimmed + modelName.trimmed).isEmpty
    }

    private var parsedYear: Int? {
        guard let value = Int(year.trimmed), (1900...2100).contains(value) else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Автомобиль") {
                    TextField("Марка", text: $make)
                    TextField("Модель", text: $modelName)
                    TextField("Год выпуска", text: $year)
                        .keyboardType(.numberPad)
                }

                Section {
                    TextField("Название (необязательно)", text: $name)
                } footer: {
                    Text("Например, «Рабочая» или «Машина жены». Если не указать, будут показаны марка и модель.")
                }

                Section("Пробег") {
                    LabeledContent("Текущий пробег, км") {
                        NumberField("0", value: $mileage)
                    }
                }

                Section("Документы") {
                    TextField("Госномер", text: $plate)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("VIN", text: $vin)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle(car == nil ? "Новый автомобиль" : "Автомобиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let target: Car
        if let car {
            target = car
        } else {
            target = Car()
            context.insert(target)
            selectedCarID = target.uuid.uuidString
        }
        target.name = name.trimmed
        target.make = make.trimmed
        target.modelName = modelName.trimmed
        target.year = parsedYear
        target.plate = plate.trimmed.uppercased()
        target.vin = vin.trimmed.uppercased()
        target.mileage = mileage
        dismiss()
    }
}
