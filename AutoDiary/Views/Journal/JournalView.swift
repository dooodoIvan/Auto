import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var context
    let car: Car

    @State private var searchText = ""
    @State private var categoryFilter: ServiceCategory?
    @State private var showingNewRecord = false
    @State private var showingMileage = false

    private var filteredRecords: [ServiceRecord] {
        car.sortedRecords.filter { record in
            if let categoryFilter, record.category != categoryFilter { return false }
            let query = searchText.trimmed
            guard !query.isEmpty else { return true }
            return record.title.localizedStandardContains(query)
                || record.notes.localizedStandardContains(query)
                || record.workshop.localizedStandardContains(query)
                || record.parts.contains { $0.name.localizedStandardContains(query) || $0.number.localizedStandardContains(query) }
        }
    }

    private var groups: [RecordGroup] {
        let calendar = Calendar.current
        let byMonth = Dictionary(grouping: filteredRecords) { record in
            calendar.date(from: calendar.dateComponents([.year, .month], from: record.date)) ?? record.date
        }
        return byMonth.keys.sorted(by: >).map { RecordGroup(month: $0, records: byMonth[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    CarSummaryCard(car: car) { showingMileage = true }
                }

                if car.records.isEmpty {
                    ContentUnavailableView(
                        "Записей пока нет",
                        systemImage: "wrench.and.screwdriver",
                        description: Text("Добавьте первое ТО или ремонт кнопкой «+».")
                    )
                    .listRowBackground(Color.clear)
                } else if groups.isEmpty {
                    if searchText.trimmed.isEmpty {
                        ContentUnavailableView("Нет записей в этой категории", systemImage: "line.3.horizontal.decrease.circle")
                            .listRowBackground(Color.clear)
                    } else {
                        ContentUnavailableView.search(text: searchText)
                            .listRowBackground(Color.clear)
                    }
                } else {
                    ForEach(groups) { group in
                        Section {
                            ForEach(group.records) { record in
                                NavigationLink(value: record) {
                                    RecordRow(record: record)
                                }
                            }
                            .onDelete { offsets in
                                offsets.map { group.records[$0] }.forEach(context.delete)
                            }
                        } header: {
                            Text(group.month, format: .dateTime.month(.wide).year())
                        }
                    }
                }
            }
            .navigationTitle(car.displayName)
            .navigationDestination(for: ServiceRecord.self) { record in
                RecordDetailView(record: record)
            }
            .searchable(text: $searchText, prompt: "Работы, запчасти, сервис")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CarSwitcherMenu(current: car)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    filterMenu
                    Button("Новая запись", systemImage: "plus") { showingNewRecord = true }
                }
            }
            .sheet(isPresented: $showingNewRecord) {
                RecordFormView(car: car, record: nil)
            }
            .sheet(isPresented: $showingMileage) {
                MileageUpdateView(car: car)
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Категория", selection: $categoryFilter) {
                Text("Все категории").tag(ServiceCategory?.none)
                ForEach(ServiceCategory.allCases) { category in
                    Label(category.title, systemImage: category.symbol).tag(ServiceCategory?.some(category))
                }
            }
        } label: {
            Label(
                "Фильтр",
                systemImage: categoryFilter == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }
}

private struct RecordGroup: Identifiable {
    let month: Date
    let records: [ServiceRecord]
    var id: Date { month }
}

private struct CarSummaryCard: View {
    let car: Car
    let onUpdateMileage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Пробег")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Fmt.km(car.mileage))
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                Spacer()
                Button("Обновить", systemImage: "speedometer", action: onUpdateMileage)
                    .buttonStyle(.bordered)
            }
            Divider()
            HStack {
                stat(title: "Расходы за \(String(Calendar.current.component(.year, from: .now)))",
                     value: Fmt.money(car.spent()))
                Spacer()
                stat(title: "Всего записей", value: String(car.records.count))
            }
        }
        .padding(.vertical, 4)
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
        }
    }
}

struct RecordRow: View {
    let record: ServiceRecord

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: record.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                Text("\(Fmt.date(record.date)) · \(Fmt.km(record.mileage))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if record.totalCost > 0 {
                Text(Fmt.money(record.totalCost))
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
            }
        }
    }
}

struct MileageUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    let car: Car
    @State private var mileage: Int

    init(car: Car) {
        self.car = car
        _mileage = State(initialValue: car.mileage)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Пробег, км") {
                        NumberField("0", value: $mileage)
                    }
                } footer: {
                    if mileage < car.mileage {
                        Text("Значение меньше текущего (\(Fmt.km(car.mileage))). Сохраняйте, только если исправляете ошибку.")
                            .foregroundStyle(.orange)
                    } else {
                        Text("Сейчас: \(Fmt.km(car.mileage)). Напоминания по пробегу пересчитаются автоматически.")
                    }
                }
            }
            .navigationTitle("Пробег")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        car.mileage = mileage
                        dismiss()
                    }
                    .disabled(mileage == 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#if DEBUG
#Preview {
    JournalView(car: SampleData.car)
        .modelContainer(SampleData.container)
}
#endif
