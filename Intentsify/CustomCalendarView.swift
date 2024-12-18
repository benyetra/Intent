//
//  CustomCalendarView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    var datesWithEntries: [Date]
    var onDateSelected: (Date) -> Void

    let calendar = Calendar.current
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(selectedDate.monthAndYear)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Days of the Week
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .foregroundColor(Color("PrimaryTextColor"))
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }

            // Days in Month
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
                    Button(action: {
                        selectedDate = date
                        onDateSelected(date)
                    }) {
                        VStack {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.body)
                                .foregroundColor(isSameDay(date, selectedDate) ? Color("PrimaryTextColor") : Color("PrimaryTextColor"))
                                .frame(width: 30, height: 30)
                                .background(isSameDay(date, selectedDate) ? Color.accentColor : Color.clear)
                                .clipShape(Circle())

                            if datesWithEntries.contains(date.startOfDay) { // Compare startOfDay
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func daysInMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        return range.compactMap { day -> Date? in
            return calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)
        }
    }

    private func changeMonth(by value: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) else { return }
        selectedDate = newDate
        onDateSelected(selectedDate)
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
}
