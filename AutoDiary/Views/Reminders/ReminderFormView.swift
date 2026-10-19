import SwiftUI
import SwiftData

struct ReminderFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let car: Car
    let reminder: Reminder?

    @State private var title: String
    @State private var notes: String
    @State private var useMileage: Bool
    @State private var dueMileage: Int
    @State private var repeatKm: Int
    @State private var useDate: Bool
    @State private var dueDate: Date
    @State private var repeatMonths: Int
    @State private var notify: Bool
    @State private var confirmingDelete = false

    private static let monthOptions = [0, 1, 3, 6, 12, 24, 36, 48, 60]

    init(car: Car, reminder: Reminder?) {
        self.car = car
        self.reminder = reminder
        let defaultDate = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
        _title = State(initialValue: reminder?.title ?? "")
        _notes = State(initialValue: reminder?.notes ?? "")
        _useMileage = State(initialValue: reminder?.dueMileage != nil)
        _dueMileage = State(initialValue: reminder?.dueMileage ?? car.mileage + 10_000)
        _repeatKm = State(initialValue: reminder?.repeatKm ?? 0)
        _useDate = State(initialValue: reminder.map { $0.dueDate != nil } ?? true)
        _dueDate = State(initialValue: reminder?.dueDate ?? defaultDate)
        _repeatMonths = State(initialValue: reminder?.repeatMonths ?? 0)
        _notify = State(initialValue: reminder?.notify ?? true)
    }

    private var canSave: Bool {
        !title.trimmed.isEmpty && (useMileage || useDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Что сделать", text: $title)
                    if reminder == nil {
                        Menu {
                            ForEach(ReminderTemplate.all) { template in
                                Button(template.title) { apply(template) }
                            }
                        } label: {
                            Label("Выбрать из типовых работ", systemImage: "list.bullet.rectangle")
                        }
                    }
                }

                Section {
                    Toggle("По пробегу", isOn: $useMileage.animation())
                    if useMileage {
                        LabeledContent("Напомнить на, км") {
                            NumberField("0", value: $dueMileage)
                        }
                        LabeledContent("Повторять каждые, км") {
                            NumberField("не повторять", value: $repeatKm)
                        }
                    }
                } footer: {
                    if useMileage {
                        Text(mileageFooter)
                    }
                }

                Section {
                    Toggle("По дате", isOn: $useDate.animation())
                    if useDate {
                        DatePicker("Дата", selection: $dueDate, displayedComponents: .date)
                        Picker("Повторять", selection: $repeatMonths) {
                            ForEach(Self.monthOptions, id: \.self) { months in
                                Text(months == 0 ? "Не повторять" : Fmt.monthsInterval(months).capitalizedFirst)
                                    .tag(months)
                            }
                        }
                        Toggle("Уведомление", isOn: $notify)
                    }
                } footer: {
                    if useDate && notify {
                        Text("Уведомление придёт за неделю и в день срока в 10:00.")
                    }
                }

                Section("Заметки") {
                    TextField("Например, какое масло заливать", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                if reminder != nil {
                    Section {
                        Button("Удалить напоминание", role: .destructive) { confirmingDelete = true }
                    }
                }
            }
            .navigationTitle(reminder == nil ? "Новое напоминание" : "Напоминание")
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
            .confirmationDialog("Удалить напоминание?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Удалить", role: .destructive, action: delete)
            }
        }
    }

    private var mileageFooter: String {
        let left = dueMileage - car.mileage
        let current = "Текущий пробег \(Fmt.km(car.mileage))."
        return left > 0 ? "\(current) Осталось \(Fmt.km(left))." : "\(current) Срок уже наступил."
    }

    private func apply(_ template: ReminderTemplate) {
        title = template.title
        if let km = template.repeatKm {
            useMileage = true
            repeatKm = km
            dueMileage = car.mileage + km
        } else {
            useMileage = false
            repeatKm = 0
        }
        if let months = template.repeatMonths {
            useDate = true
            repeatMonths = months
            dueDate = Calendar.current.date(byAdding: .month, value: months, to: .now) ?? .now
        } else {
            useDate = false
            repeatMonths = 0
        }
    }

    private func save() {
        let target: Reminder
        if let reminder {
            target = reminder
        } else {
            target = Reminder(title: "")
            context.insert(target)
            target.car = car
        }
        target.title = title.trimmed
        target.notes = notes.trimmed
        target.dueMileage = useMileage ? dueMileage : nil
        target.repeatKm = useMileage && repeatKm > 0 ? repeatKm : nil
        target.dueDate = useDate ? dueDate : nil
        target.repeatMonths = useDate && repeatMonths > 0 ? repeatMonths : nil
        target.notify = notify
        NotificationManager.shared.schedule(target)
        dismiss()
    }

    private func delete() {
        guard let reminder else { return }
        NotificationManager.shared.cancel(reminder)
        context.delete(reminder)
        dismiss()
    }
}
