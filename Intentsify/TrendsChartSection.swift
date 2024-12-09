//
//  TrendsChartSection.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import Charts
import SwiftUI

struct TrendsChartSection: View {
    var title: String
    var data: [String: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Chart {
                ForEach(data.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                    BarMark(
                        x: .value("Count", value),
                        y: .value("Category", key)
                    )
                }
            }
            .frame(height: 200)
        }
    }
}
