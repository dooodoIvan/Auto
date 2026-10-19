import Foundation

/// Типовые регламентные работы для быстрого создания напоминания.
struct ReminderTemplate: Identifiable {
    let title: String
    let repeatKm: Int?
    let repeatMonths: Int?
    let category: ServiceCategory

    var id: String { title }

    static let all: [ReminderTemplate] = [
        .init(title: "Замена моторного масла", repeatKm: 10_000, repeatMonths: 12, category: .maintenance),
        .init(title: "Замена воздушного фильтра", repeatKm: 15_000, repeatMonths: 12, category: .maintenance),
        .init(title: "Замена салонного фильтра", repeatKm: 15_000, repeatMonths: 12, category: .maintenance),
        .init(title: "Замена тормозной жидкости", repeatKm: nil, repeatMonths: 24, category: .maintenance),
        .init(title: "Замена свечей зажигания", repeatKm: 30_000, repeatMonths: nil, category: .maintenance),
        .init(title: "Замена антифриза", repeatKm: 60_000, repeatMonths: 60, category: .maintenance),
        .init(title: "Замена ремня ГРМ", repeatKm: 60_000, repeatMonths: nil, category: .maintenance),
        .init(title: "Сезонная замена шин", repeatKm: nil, repeatMonths: 6, category: .tires),
        .init(title: "Продление ОСАГО", repeatKm: nil, repeatMonths: 12, category: .other),
        .init(title: "Техосмотр", repeatKm: nil, repeatMonths: 24, category: .other),
    ]

    /// Подбирает категорию записи в журнале по названию напоминания.
    static func category(forTitle title: String) -> ServiceCategory {
        if let template = all.first(where: { $0.title == title }) { return template.category }
        return title.localizedCaseInsensitiveContains("шин") ? .tires : .maintenance
    }
}
