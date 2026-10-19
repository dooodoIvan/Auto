import Foundation
import SwiftData

enum ReminderStatus: Int, CaseIterable, Comparable {
    case overdue, soon, planned

    static func < (lhs: ReminderStatus, rhs: ReminderStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .overdue: "Просрочено"
        case .soon: "Скоро"
        case .planned: "Запланировано"
        }
    }
}

/// Когда напоминание считается «скоро».
enum ReminderThreshold {
    static let days = 30
    static let km = 1_000
    /// Средний суточный пробег для сравнения сроков в днях и километрах (~15 000 км в год).
    static let kmPerDay = 40.0
}

@Model
final class Reminder {
    var uuid: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var dueDate: Date?
    var dueMileage: Int?
    var repeatMonths: Int?
    var repeatKm: Int?
    var notify: Bool = true
    var createdAt: Date = Date.now
    var car: Car?

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        dueMileage: Int? = nil,
        repeatMonths: Int? = nil,
        repeatKm: Int? = nil,
        notify: Bool = true
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.dueMileage = dueMileage
        self.repeatMonths = repeatMonths
        self.repeatKm = repeatKm
        self.notify = notify
    }

    func daysLeft(from now: Date = .now) -> Int? {
        guard let dueDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: dueDate)
        ).day
    }

    func kmLeft(currentMileage: Int) -> Int? {
        dueMileage.map { $0 - currentMileage }
    }

    /// Срабатывает то условие, что наступит раньше: дата или пробег.
    func status(currentMileage: Int, now: Date = .now) -> ReminderStatus {
        let days = daysLeft(from: now)
        let km = kmLeft(currentMileage: currentMileage)
        if let days, days < 0 { return .overdue }
        if let km, km <= 0 { return .overdue }
        if let days, days <= ReminderThreshold.days { return .soon }
        if let km, km <= ReminderThreshold.km { return .soon }
        return .planned
    }

    /// Чем меньше, тем срочнее. Километры переводятся в дни по среднему пробегу.
    private func urgency(currentMileage: Int) -> Double {
        let byDate = daysLeft().map(Double.init) ?? .infinity
        let byKm = kmLeft(currentMileage: currentMileage).map { Double($0) / ReminderThreshold.kmPerDay } ?? .infinity
        return min(byDate, byKm)
    }

    func sortsBefore(_ other: Reminder, currentMileage: Int) -> Bool {
        let lhs = status(currentMileage: currentMileage)
        let rhs = other.status(currentMileage: currentMileage)
        if lhs != rhs { return lhs < rhs }
        return urgency(currentMileage: currentMileage) < other.urgency(currentMileage: currentMileage)
    }

    var isRepeating: Bool {
        repeatMonths != nil || repeatKm != nil
    }

    var repeatDescription: String? {
        var parts: [String] = []
        if let repeatKm { parts.append("каждые \(Fmt.km(repeatKm))") }
        if let repeatMonths { parts.append(Fmt.monthsInterval(repeatMonths)) }
        return parts.isEmpty ? nil : parts.joined(separator: " или ")
    }

    /// Следующий срок, если выполнить работу в указанный день на указанном пробеге.
    /// Для одноразового напоминания оба поля будут nil.
    func nextDue(afterDoneOn date: Date, mileage: Int) -> (date: Date?, mileage: Int?) {
        let nextDate = repeatMonths.flatMap { Calendar.current.date(byAdding: .month, value: $0, to: date) }
        let nextMileage = repeatKm.map { mileage + $0 }
        return (nextDate, nextMileage)
    }

    /// Переносит срок на следующий цикл. Возвращает false, если напоминание
    /// не повторяется и его нужно удалить.
    func markDone(on date: Date, mileage: Int) -> Bool {
        let next = nextDue(afterDoneOn: date, mileage: mileage)
        guard next.date != nil || next.mileage != nil else { return false }
        dueDate = next.date
        dueMileage = next.mileage
        return true
    }
}
