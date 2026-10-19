import Foundation
import UserNotifications

/// Локальные уведомления для напоминаний с датой: за неделю и в день срока.
/// Напоминания по пробегу показываются только внутри приложения — пробег телефон не знает.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let notifyHour = 10
    private let daysBefore = 7

    private init() {}

    func schedule(_ reminder: Reminder) {
        cancel(reminder)
        guard reminder.notify, let dueDate = reminder.dueDate else { return }

        let id = reminder.uuid.uuidString
        let title = reminder.title
        let carName = reminder.car?.displayName ?? ""
        let calendar = Calendar.current

        var plan: [(suffix: String, date: Date, body: String)] = [
            ("due", dueDate, "Сегодня срок · \(carName)"),
        ]
        if let weekBefore = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate) {
            plan.append(("week", weekBefore, "Через неделю · \(carName)"))
        }

        Task {
            guard await requestAuthorizationIfNeeded() else { return }
            for item in plan {
                var components = calendar.dateComponents([.year, .month, .day], from: item.date)
                components.hour = notifyHour
                guard let fireDate = calendar.date(from: components), fireDate > .now else { continue }

                let content = UNMutableNotificationContent()
                content.title = title
                content.body = item.body
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: "\(id).\(item.suffix)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                try? await center.add(request)
            }
        }
    }

    func cancel(_ reminder: Reminder) {
        let id = reminder.uuid.uuidString
        center.removePendingNotificationRequests(withIdentifiers: ["\(id).due", "\(id).week"])
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }
}
