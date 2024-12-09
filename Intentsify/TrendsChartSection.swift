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

            if data.isEmpty {
                Text("No data available.")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                // Dynamically generate colors for keys
                let colorPalette = [Color.red, Color.green, Color.blue, Color.orange, Color.purple]
                let dynamicColors = data.keys.enumerated().reduce(into: [String: Color]()) { result, pair in
                    result[pair.element] = colorPalette[pair.offset % colorPalette.count]
                }

                Chart {
                    ForEach(data.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                        BarMark(
                            x: .value("Count", value),
                            y: .value("Category", key)
                        )
                        .foregroundStyle(dynamicColors[key] ?? Color.gray) // Use dynamic colors
                        .annotation(position: .overlay) {
                            Text("\(value)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 300)
                .overlay(
                    GeometryReader { proxy in
                        ForEach(data.sorted(by: { $0.value > $1.value }), id: \.key) { key, _ in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onClick?(key)
                                }
                        }
                    }
                )
            }
        }
        .padding()
        .onAppear {
            print("Data for chart: \(data)")
        }
    }
}
