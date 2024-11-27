import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    var journalEntries: FetchedResults<JournalEntry>

    var body: some View {
        VStack {
            // Month and Year Navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(calendarTitle(for: selectedDate))
                    .font(.title2)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            // Days of the Week
            HStack {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day).font(.caption).frame(maxWidth: .infinity)
                }
            }

            // Calendar Grid
            let days = generateCalendarDays(for: selectedDate)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days, id: \.self) { day in
                    VStack {
                        if let day = day {
                            Button(action: {
                                selectedDate = day
                            }) {
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .frame(width: 30, height: 30)
                                    .background(
                                        Calendar.current.isDate(day, inSameDayAs: selectedDate) ? Color.blue.opacity(0.5) : Color.clear
                                    )
                                    .clipShape(Circle())
                                    .foregroundColor(isToday(day) ? .red : .primary)
                            }
                            // Dot for days with entries
                            if hasJournalEntries(on: day) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 2)
                            }
                        } else {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Methods

    private func changeMonth(by value: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func calendarTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func generateCalendarDays(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let startOfMonth = calendar.date(from: components)!
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)!.count
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - calendar.firstWeekday

        // Fill days before the first weekday with nil
        var days: [Date?] = Array(repeating: nil, count: firstWeekday < 0 ? firstWeekday + 7 : firstWeekday)

        // Add days for the current month
        for day in 1...daysInMonth {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(dayDate)
            }
        }
        return days
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func hasJournalEntries(on date: Date) -> Bool {
        let calendar = Calendar.current
        return journalEntries.contains { entry in
            if let entryDate = entry.date {
                return calendar.isDate(entryDate, inSameDayAs: date)
            }
            return false
        }
    }
}


struct EventLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: true)],
        animation: .default)
    private var journalEntries: FetchedResults<JournalEntry>

    @State private var selectedDate: Date = Date() // Default to today

    var body: some View {
        NavigationView {
            VStack {
                // Custom Calendar with Navigation
                CalendarView(
                    selectedDate: $selectedDate,
                    journalEntries: journalEntries
                )

                // Entries for Selected Day
                List {
                    ForEach(entriesForSelectedDate()) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.content ?? "No Content")
                                .font(.body)
                                .padding(.bottom, 2)

                            if let tags = entry.tags, !tags.isEmpty {
                                Text("Tags: \(tags)")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }

                            if let relationship = entry.relationship, !relationship.isEmpty {
                                Text("Relationship: \(relationship)")
                                    .font(.footnote)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .onDelete(perform: deleteEntry) // Swipe-to-delete
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Event Log")
        }
    }

    // Filter entries for the selected day
    private func entriesForSelectedDate() -> [JournalEntry] {
        let calendar = Calendar.current
        return journalEntries.filter { entry in
            if let date = entry.date {
                return calendar.isDate(date, inSameDayAs: selectedDate)
            }
            return false
        }
    }

    // Delete an entry
    private func deleteEntry(at offsets: IndexSet) {
        withAnimation {
            // Map the offsets to the filtered list, and delete from `journalEntries`
            let entriesToDelete = offsets.map { entriesForSelectedDate()[$0] }
            entriesToDelete.forEach { entry in
                if let index = journalEntries.firstIndex(of: entry) {
                    viewContext.delete(journalEntries[index])
                }
            }

            do {
                try viewContext.save()
            } catch {
                print("Error deleting entry: \(error.localizedDescription)")
            }
        }
    }
}
