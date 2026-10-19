import Foundation
import SwiftData

@Model
final class Car {
    var uuid: UUID = UUID()
    var name: String = ""
    var make: String = ""
    var modelName: String = ""
    var year: Int?
    var plate: String = ""
    var vin: String = ""
    var mileage: Int = 0
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.car)
    var records: [ServiceRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \Reminder.car)
    var reminders: [Reminder] = []

    init(
        name: String = "",
        make: String = "",
        modelName: String = "",
        year: Int? = nil,
        plate: String = "",
        vin: String = "",
        mileage: Int = 0
    ) {
        self.name = name
        self.make = make
        self.modelName = modelName
        self.year = year
        self.plate = plate
        self.vin = vin
        self.mileage = mileage
    }

    private var makeAndModel: String {
        [make, modelName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var displayName: String {
        if !name.isEmpty { return name }
        return makeAndModel.isEmpty ? "Автомобиль" : makeAndModel
    }

    /// Вторая строка в списках: марка/модель (если задано имя), год, госномер.
    var details: String {
        var parts: [String] = []
        if !name.isEmpty, !makeAndModel.isEmpty { parts.append(makeAndModel) }
        if let year { parts.append(String(year)) }
        if !plate.isEmpty { parts.append(plate) }
        return parts.joined(separator: " · ")
    }

    var sortedRecords: [ServiceRecord] {
        records.sorted { ($0.date, $0.mileage) > ($1.date, $1.mileage) }
    }

    /// Сколько напоминаний просрочено или подходит срок.
    var attentionCount: Int {
        reminders.filter { $0.status(currentMileage: mileage) != .planned }.count
    }

    func spent(inYearOf date: Date = .now) -> Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return records
            .filter { calendar.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.totalCost }
    }

    /// Пробег только растёт: запись со старым пробегом не уменьшает текущий.
    func registerMileage(_ value: Int) {
        if value > mileage { mileage = value }
    }
}
