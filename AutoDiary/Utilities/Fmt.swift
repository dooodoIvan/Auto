import Foundation

/// Форматирование чисел, денег и дат для интерфейса.
enum Fmt {
    static var currencyCode: String {
        Locale.current.currency?.identifier ?? "RUB"
    }

    static func money(_ value: Double) -> String {
        value.formatted(.currency(code: currencyCode).precision(.fractionLength(0...2)))
    }

    static func km(_ value: Int) -> String {
        "\(value.formatted()) км"
    }

    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    static func date(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    static func days(_ count: Int) -> String {
        "\(count) \(plural(count, "день", "дня", "дней"))"
    }

    static func monthsInterval(_ months: Int) -> String {
        switch months {
        case 1: return "каждый месяц"
        case 6: return "каждые полгода"
        case 12: return "каждый год"
        case let m where m % 12 == 0:
            let years = m / 12
            return "каждые \(years) \(plural(years, "год", "года", "лет"))"
        default:
            return "каждые \(months) мес."
        }
    }

    /// Русское склонение: 1 день, 2 дня, 5 дней.
    static func plural(_ n: Int, _ one: String, _ few: String, _ many: String) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return one }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return few }
        return many
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
