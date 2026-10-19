import Foundation
import SwiftData

enum ServiceCategory: String, CaseIterable, Identifiable, Codable {
    case maintenance, repair, tires, diagnostics, body, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .maintenance: "ТО"
        case .repair: "Ремонт"
        case .tires: "Шины"
        case .diagnostics: "Диагностика"
        case .body: "Кузов"
        case .other: "Другое"
        }
    }

    var symbol: String {
        switch self {
        case .maintenance: "wrench.and.screwdriver.fill"
        case .repair: "hammer.fill"
        case .tires: "circle.circle.fill"
        case .diagnostics: "stethoscope"
        case .body: "car.side.fill"
        case .other: "ellipsis.circle.fill"
        }
    }
}

@Model
final class ServiceRecord {
    var date: Date = Date.now
    var mileage: Int = 0
    var categoryRaw: String = "maintenance"
    var title: String = ""
    var workshop: String = ""
    var laborCost: Double = 0
    var notes: String = ""
    var car: Car?

    @Relationship(deleteRule: .cascade, inverse: \Part.record)
    var parts: [Part] = []

    init(
        title: String = "",
        category: ServiceCategory = .maintenance,
        date: Date = .now,
        mileage: Int = 0,
        workshop: String = "",
        laborCost: Double = 0,
        notes: String = ""
    ) {
        self.title = title
        self.categoryRaw = category.rawValue
        self.date = date
        self.mileage = mileage
        self.workshop = workshop
        self.laborCost = laborCost
        self.notes = notes
    }

    var category: ServiceCategory {
        get { ServiceCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var sortedParts: [Part] {
        parts.sorted { $0.sortIndex < $1.sortIndex }
    }

    var partsCost: Double {
        parts.reduce(0) { $0 + $1.total }
    }

    var totalCost: Double {
        laborCost + partsCost
    }
}

@Model
final class Part {
    var name: String = ""
    var number: String = ""
    var quantity: Double = 1
    var price: Double = 0
    var sortIndex: Int = 0
    var record: ServiceRecord?

    init(name: String, number: String = "", quantity: Double = 1, price: Double = 0, sortIndex: Int = 0) {
        self.name = name
        self.number = number
        self.quantity = quantity
        self.price = price
        self.sortIndex = sortIndex
    }

    var total: Double {
        quantity * price
    }
}
