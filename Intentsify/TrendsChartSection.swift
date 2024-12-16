import SwiftUI
import Charts

struct TrendsChartSection: View {
    var title: String
    var relatedPeopleData: [RelationshipData]
    var onClick: ((String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            if relatedPeopleData.isEmpty {
                Text("No data available.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                RadarChartView(relationshipsData: relatedPeopleData)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.vertical, 10)
            }
        }
        .background(Color("SecondaryBackgroundColor"))
        .cornerRadius(10)
        .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)
        .padding([.horizontal, .top])
    }
}

struct RelationshipData {
    let name: String
    let successCount: Int
    let failureCount: Int
}
   
private func position(for angle: CGFloat, radius: CGFloat, center: CGPoint) -> CGPoint {
    CGPoint(
        x: center.x + radius * cos(angle),
        y: center.y + radius * sin(angle)
    )
}
