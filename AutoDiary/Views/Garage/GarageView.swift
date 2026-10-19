import SwiftUI
import SwiftData

struct GarageView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @AppStorage("selectedCarID") private var selectedCarID = ""
    @State private var showingNewCar = false
    @State private var editingCar: Car?
    @State private var carToDelete: Car?

    private var currentID: String? {
        (cars.first { $0.uuid.uuidString == selectedCarID } ?? cars.first)?.uuid.uuidString
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(cars) { car in
                        Button {
                            selectedCarID = car.uuid.uuidString
                        } label: {
                            CarRow(car: car, isSelected: car.uuid.uuidString == currentID)
                        }
                        .foregroundStyle(.primary)
                        .swipeActions {
                            Button {
                                carToDelete = car
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            .tint(.red)

                            Button {
                                editingCar = car
                            } label: {
                                Label("Изменить", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button("Изменить", systemImage: "pencil") { editingCar = car }
                            Button("Удалить", systemImage: "trash", role: .destructive) { carToDelete = car }
                        }
                    }
                } footer: {
                    if cars.count > 1 {
                        Text("Нажмите на автомобиль, чтобы сделать его текущим в журнале и напоминаниях.")
                    }
                }
            }
            .navigationTitle("Гараж")
            .toolbar {
                Button("Добавить", systemImage: "plus") { showingNewCar = true }
            }
            .sheet(isPresented: $showingNewCar) {
                CarFormView(car: nil)
            }
            .sheet(item: $editingCar) { car in
                CarFormView(car: car)
            }
            .confirmationDialog(
                "Удалить автомобиль?",
                isPresented: Binding(get: { carToDelete != nil }, set: { if !$0 { carToDelete = nil } }),
                titleVisibility: .visible,
                presenting: carToDelete
            ) { car in
                Button("Удалить «\(car.displayName)»", role: .destructive) { delete(car) }
            } message: { _ in
                Text("Вся история обслуживания и напоминания этого автомобиля будут удалены.")
            }
        }
    }

    private func delete(_ car: Car) {
        car.reminders.forEach(NotificationManager.shared.cancel)
        if car.uuid.uuidString == selectedCarID { selectedCarID = "" }
        context.delete(car)
    }
}

private struct CarRow: View {
    let car: Car
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(car.displayName)
                    .font(.headline)
                if !car.details.isEmpty {
                    Text(car.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(Fmt.km(car.mileage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    GarageView()
        .modelContainer(SampleData.container)
}
#endif
