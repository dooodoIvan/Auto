import SwiftUI
import SwiftData

/// Отметка о выполнении: пишет запись в журнал и переносит напоминание на следующий цикл.
struct CompleteReminderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let car: Car
    let reminder: Reminder

    @State private var date: Date = .now
    @State private var mileage: Int
    @State private var addRecord = true
    @State private var category: ServiceCategory
    @State private var cost: Double = 0
    @State private var workshop = ""

    init(car: Car, reminder: Reminder) {
        self.car = car
        self.reminder = reminder
        _mileage = State(initialValue: car.mileage)
        _category = State(initialValue: ReminderTemplate.category(forTitle: reminder.title))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Работа", value: reminder.title)
                    DatePicker("Дата", selection: $date, in: ...Date.now, displayedComponents: .date)
                    LabeledContent("Пробег, км") {
                        NumberField("0", value: $mileage)
                    }
                }

                Section {
                    Toggle("Добавить запись в журнал", isOn: $addRecord.animation())
                    if addRecord {
                        Picker("Категория", selection: $category) {
                            ForEach(ServiceCategory.allCases) { category in
                                Text(category.title).tag(category)
                            }
                        }
                        LabeledContent("Стоимость") {
                            DecimalField("0", value: $cost)
                        }
                        TextField("Сервис или мастер", text: $workshop)
                    }
                } footer: {
                    if addRecord {
                        Text("Запчасти и подробности можно добавить позже, открыв запись в журнале.")
                    }
                }

                Section {
                    Text(nextDueText)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Дальше")
                }
            }
            .navigationTitle("Выполнено")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово", action: complete)
                }
            }
        }
    }

    private var nextDueText: String {
        let next = reminder.nextDue(afterDoneOn: date, mileage: mileage)
        var parts: [String] = []
        if let km = next.mileage { parts.append("на \(Fmt.km(km))") }
        if let nextDate = next.date { parts.append(Fmt.date(nextDate)) }
        if parts.isEmpty {
            return "Напоминание не повторяется и будет удалено."
        }
        return "Следующее напоминание: \(parts.joined(separator: " или "))."
    }

    private func complete() {
        car.registerMileage(mileage)

        if addRecord {
            let record = ServiceRecord(
                title: reminder.title,
                category: category,
                date: date,
                mileage: mileage,
                workshop: workshop.trimmed,
                laborCost: cost,
                notes: reminder.notes
            )
            context.insert(record)
            record.car = car
        }

        if reminder.markDone(on: date, mileage: mileage) {
            NotificationManager.shared.schedule(reminder)
        } else {
            NotificationManager.shared.cancel(reminder)
            context.delete(reminder)
        }
        dismiss()
    }
}
