import SwiftUI
import Charts

struct TrendsChartSection: View {
    var title: String
    var data: [String: Int]
    var onClick: ((String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            if data.isEmpty {
                Text("No data available.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                Chart {
                    ForEach(data.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                        BarMark(
                            x: .value("Count", value),
                            y: .value("Goal", key)
                        )
                        .foregroundStyle(Color.accentColor)
                        .annotation(position: .overlay) {
                            Text("\(value)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: max(150, CGFloat(data.count) * 50)) // Dynamic height for better fit
                .padding(.vertical, 10) // Add space around the chart
            }
        }
        .background(Color("SecondaryBackgroundColor"))
        .cornerRadius(10)
        .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)
        .padding([.horizontal, .top])
    }
}


extension View {
    func chartStyle() -> some View {
        self
            .background(Color("SecondaryBackgroundColor"))
            .cornerRadius(10)
            .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)
            .padding([.horizontal, .top])
    }
}

