import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var context
    let car: Car

    @State private var showingNew = false
    @State private var editing: Reminder?
    @State private var completing: Reminder?

    private var sortedReminders: [Reminder] {
        car.reminders.sorted { $0.sortsBefore($1, currentMileage: car.mileage) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(ReminderStatus.allCases, id: \.self) { status in
                    let items = sortedReminders.filter { $0.status(currentMileage: car.mileage) == status }
                    if !items.isEmpty {
                        Section(status.title) {
                            ForEach(items) { reminder in
                                row(for: reminder)
                            }
                        }
                    }
                }
            }
            .overlay {
                if car.reminders.isEmpty {
                    ContentUnavailableView {
                        Label("Нет напоминаний", systemImage: "bell.slash")
                    } description: {
                        Text("Замена масла, страховка, техосмотр — напомним по дате или пробегу.")
                    } actions: {
                        Button("Добавить напоминание") { showingNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Напоминания")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CarSwitcherMenu(current: car)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Новое напоминание", systemImage: "plus") { showingNew = true }
                }
            }
            .sheet(isPresented: $showingNew) {
                ReminderFormView(car: car, reminder: nil)
            }
            .sheet(item: $editing) { reminder in
                ReminderFormView(car: car, reminder: reminder)
            }
            .sheet(item: $completing) { reminder in
                CompleteReminderView(car: car, reminder: reminder)
            }
        }
    }

    private func row(for reminder: Reminder) -> some View {
        ReminderRow(reminder: reminder, currentMileage: car.mileage) {
            completing = reminder
        }
        .contentShape(Rectangle())
        .onTapGesture { editing = reminder }
        .swipeActions(edge: .leading) {
            Button {
                completing = reminder
            } label: {
                Label("Выполнено", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                NotificationManager.shared.cancel(reminder)
                context.delete(reminder)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}

private struct ReminderRow: View {
    let reminder: Reminder
    let currentMileage: Int
    let onComplete: () -> Void

    var body: some View {
        let status = reminder.status(currentMileage: currentMileage)
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status.symbol)
                .font(.title3)
                .foregroundStyle(status.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                Group {
                    if let mileageLine {
                        Label(mileageLine, systemImage: "speedometer")
                    }
                    if let dateLine {
                        Label(dateLine, systemImage: "calendar")
                    }
                    if let repeatLine = reminder.repeatDescription {
                        Label(repeatLine.capitalizedFirst, systemImage: "repeat")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(action: onComplete) {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Отметить выполненным")
        }
        .padding(.vertical, 2)
    }

    private var mileageLine: String? {
        guard let due = reminder.dueMileage else { return nil }
        let left = due - currentMileage
        let target = "на \(Fmt.km(due))"
        if left > 0 { return "\(target) · осталось \(Fmt.km(left))" }
        if left == 0 { return "\(target) · пора" }
        return "\(target) · просрочено на \(Fmt.km(-left))"
    }

    private var dateLine: String? {
        guard let due = reminder.dueDate, let days = reminder.daysLeft() else { return nil }
        let date = Fmt.date(due)
        if days > 0 { return "\(date) · через \(Fmt.days(days))" }
        if days == 0 { return "\(date) · сегодня" }
        return "\(date) · просрочено на \(Fmt.days(-days))"
    }
}

#if DEBUG
#Preview {
    RemindersView(car: SampleData.car)
        .modelContainer(SampleData.container)
}
#endif
