#if DEBUG
import Foundation
import SwiftData

/// Тестовые данные для превью в Xcode.
@MainActor
enum SampleData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(
            for: Car.self, ServiceRecord.self, Part.self, Reminder.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let car = Car(make: "Skoda", modelName: "Octavia", year: 2019, plate: "А123ВС77", mileage: 87_450)
        context.insert(car)
        context.insert(Car(name: "Дача", make: "Lada", modelName: "Niva", year: 2015, mileage: 132_000))

        let calendar = Calendar.current
        func daysAgo(_ days: Int) -> Date { calendar.date(byAdding: .day, value: -days, to: .now)! }
        func daysAhead(_ days: Int) -> Date { calendar.date(byAdding: .day, value: days, to: .now)! }

        let oilChange = ServiceRecord(
            title: "ТО-6: масло и фильтры",
            category: .maintenance,
            date: daysAgo(40),
            mileage: 85_200,
            workshop: "Автосервис на Ленина",
            laborCost: 2_500
        )
        context.insert(oilChange)
        oilChange.car = car
        for (index, part) in [
            Part(name: "Масло Shell Helix 5W-30", number: "550046268", quantity: 4.5, price: 900),
            Part(name: "Масляный фильтр", number: "04E115561H", quantity: 1, price: 650),
            Part(name: "Салонный фильтр", quantity: 1, price: 1_100),
        ].enumerated() {
            part.sortIndex = index
            context.insert(part)
            part.record = oilChange
        }

        for record in [
            ServiceRecord(title: "Замена передних колодок", category: .repair, date: daysAgo(120), mileage: 81_000, laborCost: 1_800),
            ServiceRecord(title: "Переобувка на летние", category: .tires, date: daysAgo(190), mileage: 78_300, laborCost: 2_400),
            ServiceRecord(title: "Компьютерная диагностика", category: .diagnostics, date: daysAgo(200), mileage: 78_000, laborCost: 1_500),
        ] {
            context.insert(record)
            record.car = car
        }

        for reminder in [
            Reminder(title: "Замена моторного масла", dueDate: daysAhead(325), dueMileage: 95_200, repeatMonths: 12, repeatKm: 10_000),
            Reminder(title: "Продление ОСАГО", dueDate: daysAhead(12), repeatMonths: 12),
            Reminder(title: "Сезонная замена шин", dueDate: daysAgo(3), repeatMonths: 6),
            Reminder(title: "Замена свечей зажигания", dueMileage: 88_000, repeatKm: 30_000),
        ] {
            context.insert(reminder)
            reminder.car = car
        }

        return container
    }()

    static var car: Car {
        let descriptor = FetchDescriptor<Car>(sortBy: [SortDescriptor(\.createdAt)])
        return try! container.mainContext.fetch(descriptor).first!
    }
}
#endif
