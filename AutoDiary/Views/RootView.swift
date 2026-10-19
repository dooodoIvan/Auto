import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \Car.createdAt) private var cars: [Car]
    @AppStorage("selectedCarID") private var selectedCarID = ""

    private var selectedCar: Car? {
        cars.first { $0.uuid.uuidString == selectedCarID } ?? cars.first
    }

    var body: some View {
        if let car = selectedCar {
            TabView {
                JournalView(car: car)
                    .tabItem { Label("Журнал", systemImage: "book.closed") }

                RemindersView(car: car)
                    .tabItem { Label("Напоминания", systemImage: "bell") }
                    .badge(car.attentionCount)

                GarageView()
                    .tabItem { Label("Гараж", systemImage: "car.2") }
            }
        } else {
            WelcomeView()
        }
    }
}

struct WelcomeView: View {
    @State private var showingNewCar = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "car.side.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            VStack(spacing: 8) {
                Text("Дневник автомобилиста")
                    .font(.title.bold())
                Text("Храните историю ТО и ремонтов и не пропускайте замену масла, страховку и техосмотр.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showingNewCar = true
            } label: {
                Text("Добавить автомобиль")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .sheet(isPresented: $showingNewCar) {
            CarFormView(car: nil)
        }
    }
}

#if DEBUG
#Preview("С данными") {
    RootView()
        .modelContainer(SampleData.container)
}

#Preview("Пусто") {
    RootView()
        .modelContainer(for: Car.self, inMemory: true)
}
#endif
