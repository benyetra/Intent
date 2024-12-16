import SwiftUI

struct RadarChartView: View {
    var relationshipsData: [RelationshipData]
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size / 2 - 40 // Adjust padding dynamically
            let center = CGPoint(x: size / 2, y: size / 2)
            let dataCount = relationshipsData.count
            let maxValue = relationshipsData.flatMap { [$0.successCount, $0.failureCount] }.max() ?? 1
            
            ZStack {
                // Radar Chart Grid
                ForEach(1...5, id: \.self) { step in
                    PolygonShape(sides: dataCount, scale: CGFloat(step) / 5.0)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: size, height: size)
                        .position(center)
                }
                
                // Green Success Overlay
                PolygonShape(
                    sides: dataCount,
                    points: chartPoints(radius: radius, center: center, filterPositive: true, maxValue: maxValue)
                )
                .fill(Color.green.opacity(0.4))
                
                // Red Failure Overlay
                PolygonShape(
                    sides: dataCount,
                    points: chartPoints(radius: radius, center: center, filterPositive: false, maxValue: maxValue)
                )
                .fill(Color.red.opacity(0.4))
                
                // Labels with Values
                ForEach(0..<dataCount, id: \.self) { index in
                    let angle = CGFloat(index) * (2 * .pi / CGFloat(dataCount))
                    let labelRadius = radius + 25 // Extra padding for labels
                    let labelPosition = CGPoint(
                        x: center.x + labelRadius * cos(angle),
                        y: center.y + labelRadius * sin(angle)
                    )
                    let relationship = relationshipsData[index]
                    
                    VStack {
                        Text(relationship.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("\(relationship.successCount) / \(relationship.failureCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .position(labelPosition)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width) // Ensures it stays square
        }
        .aspectRatio(1, contentMode: .fit) // Preserve square aspect ratio
    }
    
    private func chartPoints(radius: CGFloat, center: CGPoint, filterPositive: Bool, maxValue: Int) -> [CGPoint] {
        let dataCount = relationshipsData.count
        
        return (0..<dataCount).map { index in
            let angle = CGFloat(index) * (2 * .pi / CGFloat(dataCount))
            let value = filterPositive ? relationshipsData[index].successCount : relationshipsData[index].failureCount
            let scale = CGFloat(value) / CGFloat(maxValue)
            
            return CGPoint(
                x: center.x + scale * radius * cos(angle),
                y: center.y + scale * radius * sin(angle)
            )
        }
    }
}

struct PolygonShape: Shape {
    var sides: Int
    var scale: CGFloat = 1.0
    var points: [CGPoint] = []

    func path(in rect: CGRect) -> Path {
        Path { path in
            if !points.isEmpty {
                path.addLines(points)
                path.closeSubpath()
                return
            }

            let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
            let radius = min(rect.width, rect.height) / 2 * scale

            let angle = 2 * .pi / CGFloat(sides)
            let startPoint = CGPoint(x: center.x + radius * cos(0), y: center.y + radius * sin(0))
            path.move(to: startPoint)

            for i in 1..<sides {
                let x = center.x + radius * cos(angle * CGFloat(i))
                let y = center.y + radius * sin(angle * CGFloat(i))
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.closeSubpath()
        }
    }
}
