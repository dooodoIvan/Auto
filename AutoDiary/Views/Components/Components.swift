import SwiftUI
import SwiftData

extension ServiceCategory {
    var color: Color {
        switch self {
        case .maintenance: .blue
        case .repair: .orange
        case .tires: .purple
        case .diagnostics: .teal
        case .body: .pink
        case .other: .gray
        }
    }
}

extension ReminderStatus {
    var color: Color {
        switch self {
        case .overdue: .red
        case .soon: .orange
        case .planned: .secondary
        }
    }

    var symbol: String {
        switch self {
        case .overdue: "exclamationmark.circle.fill"
        case .soon: "clock.fill"
        case .planned: "calendar"
        }
    }
}

struct CategoryIcon: View {
    let category: ServiceCategory
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(category.color.gradient, in: RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
    }
}

/// Переключатель текущего автомобиля в панели навигации. Скрыт, если машина одна.
struct CarSwitcherMenu: View {
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @AppStorage("selectedCarID") private var selectedCarID = ""
    let current: Car

    var body: some View {
        if cars.count > 1 {
            Menu {
                Picker("Автомобиль", selection: selection) {
                    ForEach(cars) { car in
                        Text(car.displayName).tag(car.uuid.uuidString)
                    }
                }
            } label: {
                Label("Сменить автомобиль", systemImage: "car.2.fill")
            }
        }
    }

    private var selection: Binding<String> {
        Binding(get: { current.uuid.uuidString }, set: { selectedCarID = $0 })
    }
}

// MARK: - Поля ввода чисел
//
// TextField(value:format:) обновляет значение только по завершении ввода, и если
// сразу нажать «Сохранить», последнее число теряется. Эти поля держат текст
// и пересчитывают значение на каждое нажатие.

struct NumberField: View {
    private let title: String
    @Binding private var value: Int
    @State private var text: String

    init(_ title: String, value: Binding<Int>) {
        self.title = title
        _value = value
        _text = State(initialValue: value.wrappedValue == 0 ? "" : String(value.wrappedValue))
    }

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .onChange(of: text) { _, newText in
                let digits = String(newText.filter { $0.isASCII && $0.isNumber }.prefix(9))
                if digits != newText {
                    text = digits
                    return
                }
                value = Int(digits) ?? 0
            }
            .onChange(of: value) { _, newValue in
                if (Int(text) ?? 0) != newValue {
                    text = newValue == 0 ? "" : String(newValue)
                }
            }
    }
}

struct DecimalField: View {
    private let title: String
    @Binding private var value: Double
    @State private var text: String

    init(_ title: String, value: Binding<Double>) {
        self.title = title
        _value = value
        _text = State(initialValue: Self.format(value.wrappedValue))
    }

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .onChange(of: text) { _, newText in
                value = Self.parse(newText) ?? 0
            }
            .onChange(of: value) { _, newValue in
                if (Self.parse(text) ?? 0) != newValue {
                    text = Self.format(newValue)
                }
            }
    }

    private static func parse(_ text: String) -> Double? {
        let cleaned = text.filter { !$0.isWhitespace }.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    private static func format(_ value: Double) -> String {
        value == 0 ? "" : value.formatted(.number.grouping(.never).precision(.fractionLength(0...2)))
    }
}
