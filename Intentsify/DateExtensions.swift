//
//  DateExtensions.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }

    var monthAndYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
