import SwiftUI
import MapKit
import CloudKit

struct TrendsDashboardView: View {
    @AppStorage("userRecordID") private var userRecordID: String = ""
    @State private var goalStreaks: [String: Int] = [:]
    @State private var goalTrends: [String: Int] = [:]
    @State private var journalLocations: [(coordinate: CLLocationCoordinate2D, goalName: String, isSuccess: Bool)] = []
    @State private var isLoading: Bool = true
    @State private var alertMessage: AlertMessage?

    var body: some View {
        NavigationView {
            ZStack {
                Color("LightBackgroundColor").ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading Trends...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Streak Progress
                            StreakProgressView(
                                streaks: goalStreaks,
                                longestStreak: goalStreaks.values.max() ?? 1
                            )
                            .cardStyle()

                            // Trends Charts
                            TrendsChartSection(
                                title: "Goal Trends",
                                data: goalTrends,
                                onClick: { goal in
                                    print("Tapped on goal: \(goal)")
                                }
                            )
                            .cardStyle()

                            // Heat Map
                            HeatMapView(locations: journalLocations)
                                .frame(height: 300)
                                .cardStyle()
                        }
                        .padding()
                    }
                    .navigationTitle("Trends")
                }
            }
            .onAppear {
                fetchTrendsData()
            }
            .alert(item: $alertMessage) { alert in
                Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func fetchTrendsData() {
        guard !userRecordID.isEmpty else {
            alertMessage = AlertMessage(message: "User not logged in.")
            return
        }

        isLoading = true
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let predicate = NSPredicate(format: "userID == %@", CKRecord.Reference(recordID: CKRecord.ID(recordName: userRecordID), action: .none))
        let query = CKQuery(recordType: "JournalEntry", predicate: predicate)

        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 100) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let matchResults):
                    let records = matchResults.matchResults.compactMap { _, result in
                        try? result.get()
                    }
                    self.processRecords(records)
                case .failure(let error):
                    self.alertMessage = AlertMessage(message: "Failed to fetch trends: \(error.localizedDescription)")
                }
            }
        }
    }

    private func processRecords(_ records: [CKRecord]) {
        var locations: [(coordinate: CLLocationCoordinate2D, goalName: String, isSuccess: Bool)] = []
        var goalCounts: [String: Int] = [:]
        var streakData: [String: [Date]] = [:]

        for record in records {
            if let location = record["location"] as? CLLocation,
               let goalName = record["goalTag"] as? String {
                // Corrected logic to parse isSuccess
                let isSuccess: Bool
                if let goalStatus = record["goalAchieved"] as? String {
                    isSuccess = goalStatus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
                } else {
                    isSuccess = false
                }
                print("Goal: \(goalName), Success: \(isSuccess), Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                locations.append((coordinate: location.coordinate, goalName: goalName, isSuccess: isSuccess))
            }

            let goalTag = record["goalTag"] as? String ?? "None"
            goalCounts[goalTag, default: 0] += 1

            if let entryDate = (record["entryDate"] as? Date)?.startOfDay {
                streakData[goalTag, default: []].append(entryDate)
            }
        }

        self.journalLocations = locations
        self.goalTrends = goalCounts
        self.goalStreaks = calculateStreaks(from: streakData)
    }

    private func calculateStreaks(from streakData: [String: [Date]]) -> [String: Int] {
        var calculatedStreaks: [String: Int] = [:]
        for (goal, dates) in streakData {
            let sortedDates = dates.sorted()
            var streak = 1
            for i in 1..<sortedDates.count {
                if Calendar.current.isDate(sortedDates[i - 1].addingTimeInterval(86400), equalTo: sortedDates[i], toGranularity: .day) {
                    streak += 1
                } else {
                    streak = max(streak, 1)
                }
            }
            calculatedStreaks[goal] = streak
        }
        return calculatedStreaks
    }
}

struct StreakProgressView: View {
    var streaks: [String: Int]
    var longestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Goal Streaks")
                .font(.headline)

            ForEach(streaks.sorted(by: { $0.value > $1.value }), id: \.key) { goal, streak in
                HStack {
                    Text(goal)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(streak) days")
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(streak), total: Double(longestStreak))
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
            }
        }
        .padding()
    }
}

struct HeatMapView: UIViewRepresentable {
    var locations: [(coordinate: CLLocationCoordinate2D, goalName: String, isSuccess: Bool)]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)

        // Add annotations
        let annotations = locations.map { location -> CustomAnnotation in
            CustomAnnotation(
                coordinate: location.coordinate,
                title: location.goalName,
                isSuccess: location.isSuccess
            )
        }
        uiView.addAnnotations(annotations)

        // Add overlays
        let overlays = locations.map { location in
            let circle = CustomCircle(center: location.coordinate, radius: 15000)
            circle.isSuccess = location.isSuccess
            return circle
        }
        uiView.addOverlays(overlays)

        if !locations.isEmpty {
            let region = regionThatFits(locations: locations.map(\.coordinate), in: uiView)
            uiView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func regionThatFits(locations: [CLLocationCoordinate2D], in mapView: MKMapView) -> MKCoordinateRegion {
        guard !locations.isEmpty else { return mapView.region }

        let maxLatitude = locations.map(\.latitude).max()!
        let minLatitude = locations.map(\.latitude).min()!
        let maxLongitude = locations.map(\.longitude).max()!
        let minLongitude = locations.map(\.longitude).min()!

        let center = CLLocationCoordinate2D(
            latitude: (maxLatitude + minLatitude) / 2,
            longitude: (maxLongitude + minLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLatitude - minLatitude) * 1.5,
            longitudeDelta: (maxLongitude - minLongitude) * 1.5
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: HeatMapView

        init(_ parent: HeatMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let circleOverlay = overlay as? CustomCircle else { return MKOverlayRenderer() }

            let renderer = MKCircleRenderer(circle: circleOverlay)
            renderer.fillColor = circleOverlay.isSuccess ? UIColor.green.withAlphaComponent(0.3) : UIColor.red.withAlphaComponent(0.3)
            renderer.strokeColor = circleOverlay.isSuccess ? UIColor.green : UIColor.red
            renderer.lineWidth = 1
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let customAnnotation = annotation as? CustomAnnotation else { return nil }
            let identifier = "CustomAnnotationView"

            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            annotationView?.annotation = annotation
            annotationView?.markerTintColor = customAnnotation.isSuccess ? UIColor.green : UIColor.red
            annotationView?.glyphImage = customAnnotation.isSuccess ? UIImage(systemName: "checkmark.seal.fill") : UIImage(systemName: "x.circle.fill")
            annotationView?.titleVisibility = .visible
            annotationView?.subtitleVisibility = .hidden

            return annotationView
        }
    }
}


class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var isSuccess: Bool

    init(coordinate: CLLocationCoordinate2D, title: String?, isSuccess: Bool) {
        self.coordinate = coordinate
        self.title = title
        self.isSuccess = isSuccess
        super.init()
        print("Annotation Created - Title: \(title ?? "No Title"), Success: \(isSuccess)")
    }
}

class CustomCircle: MKCircle {
    var isSuccess: Bool = false
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Color("SecondaryBackgroundColor"))
            .cornerRadius(10)
            .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)
    }
}
