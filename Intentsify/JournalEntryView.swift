    //
    //  JournalEntryView.swift
    //  Intentsify
    //
    //  Created by Bennett Yetra on 12/9/24.
    //

    import SwiftUI
    import MapKit
    import CoreLocation
    import CloudKit

    struct JournalEntryView: View {
        @AppStorage("userRecordID") private var userRecordID: String = ""
        @StateObject private var locationManager = LocationManager()
        
        @State private var journalText: String = ""
        @State private var entryDate: Date = Date()
        @State private var goalTag: String = ""
        @State private var relatedPeople: String = "" // Relationship field
        @State private var locationQuery: String = "" // Location field
        @State private var selectedLocation: CLLocation? = nil // Allow optional location
        @State private var goalAchieved: String = "" // Track thumbs-up or thumbs-down
        @State private var isSaving: Bool = false
        @State private var showAlert: Bool = false
        @State private var alertMessage: String = ""
        @State private var showCheckmark: Bool = false // To control the checkmark animation
        
        // For location search
        @State private var searchResults: [MKLocalSearchCompletion] = []
        @State private var searchCompleter: MKLocalSearchCompleter = {
            let completer = MKLocalSearchCompleter()
            completer.resultTypes = [.address, .pointOfInterest]
            return completer
        }()
        @State private var locationSearchDelegate: LocationSearchDelegate?
        
        var body: some View {
            ZStack {
                NavigationView {
                    ZStack {
                        Color("LightBackgroundColor").ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            datePickerSection
                            journalSection
                            goalTagSection
                            relationshipSection
                            locationSearchSection
                            goalAchievedSection
                            saveButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .navigationTitle("Journal Entry")
                        .navigationBarTitleDisplayMode(.inline)
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Error"),
                                message: Text(alertMessage),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
                // Checkmark Animation Overlay
                if showCheckmark {
                    ZStack {
                        Color.gray.opacity(0.4)
                            .ignoresSafeArea()
                            .blur(radius: 5)
                        
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(Color("AccentColor"))
                                .scaleEffect(showCheckmark ? 1 : 0.5)
                                .opacity(showCheckmark ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: showCheckmark)
                            
                            Text("Entry Saved!")
                                .font(.headline)
                                .foregroundColor(Color("PrimaryTextColor"))
                                .padding(.top, 8)
                        }
                    }
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                self.showCheckmark = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                setupSearchCompleter()
                locationManager.requestLocationPermission()
            }
        }
        
        private func setupSearchCompleter() {
            let delegate = LocationSearchDelegate { results in
                self.searchResults = results
            }
            searchCompleter.delegate = delegate
            locationSearchDelegate = delegate // Retain the delegate
        }
        
        private var relationshipSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Related People")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))
                
                TextField("Add names of people (e.g., 'John, Jane')", text: $relatedPeople)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("SecondaryBackgroundColor"))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(relatedPeople.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 1)
                    )
            }
        }
        
        private var locationSearchSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))
                
                VStack {
                    TextField("Search for a location", text: $locationQuery, onEditingChanged: { _ in
                        searchCompleter.queryFragment = locationQuery
                    })
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("SecondaryBackgroundColor"))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(locationQuery.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 1)
                    )
                    
                    if !searchResults.isEmpty {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(searchResults, id: \.self) { result in
                                    Button(action: {
                                        resolveLocation(from: result)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(result.title)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                if !result.subtitle.isEmpty {
                                                    Text(result.subtitle)
                                                        .font(.footnote)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color("SecondaryBackgroundColor"))
                                        )
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
        }
        
        
        private var datePickerSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Date and Time")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))
                
                DatePicker("Select Date and Time", selection: $entryDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("SecondaryBackgroundColor"))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("AccentColor"), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        private var journalSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Description")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))
                
                TextEditor(text: $journalText)
                    .frame(height: 80)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("SecondaryBackgroundColor"))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(journalText.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 2)
                    )
                    .scrollContentBackground(.hidden)
            }
        }
        
        private var goalTagSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tag a Goal")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))
                
                TextField("Add a goal tag (e.g., 'Fitness', 'Career')", text: $goalTag)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("SecondaryBackgroundColor"))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(goalTag.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 1)
                    )
            }
        }
        
        private var goalAchievedSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Did you progress this goal?")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))
                
                HStack(spacing: 16) {
                    Button(action: { goalAchieved = "true" }) {
                        HStack {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("Yes")
                        }
                        .foregroundColor(goalAchieved == "true" ? .green : .gray)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(goalAchieved == "true" ? Color.green.opacity(0.2) : Color.clear)
                        )
                    }
                    
                    Button(action: { goalAchieved = "false" }) {
                        HStack {
                            Image(systemName: "hand.thumbsdown.fill")
                            Text("No")
                        }
                        .foregroundColor(goalAchieved == "false" ? .red : .gray)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(goalAchieved == "false" ? Color.red.opacity(0.2) : Color.clear)
                        )
                    }
                }
            }
        }
        
        private var saveButton: some View {
            Button(action: saveJournalEntry) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                    } else {
                        Text("Submit Entry")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("AccentColor"))
                .cornerRadius(8)
            }
            .disabled(isSaving)
        }
        
        private func showAlert(message: String) {
            alertMessage = message
            showAlert = true
        }
        
        private func resolveLocation(from result: MKLocalSearchCompletion) {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = result.title + ", " + result.subtitle // Include subtitle for better precision
            let search = MKLocalSearch(request: searchRequest)

            search.start { response, error in
                if let error = error {
                    self.showAlert(message: "Failed to resolve location: \(error.localizedDescription)")
                    print("Error resolving location: \(error.localizedDescription)")
                    return
                }

                guard let mapItem = response?.mapItems.first else {
                    self.showAlert(message: "No matching location found.")
                    print("No location found for query: \(result.title), \(result.subtitle)")
                    return
                }

                // Validate the coordinates are not the San Francisco default (or any invalid fallback)
                let coordinate = mapItem.placemark.coordinate
                if coordinate.latitude == 0 && coordinate.longitude == 0 {
                    self.showAlert(message: "Location does not have valid coordinates.")
                    print("Invalid coordinates for location: \(result.title), \(result.subtitle)")
                    return
                }

                // Successfully resolved location
                self.selectedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                self.locationQuery = result.title + ", " + result.subtitle // Update UI with the selected result
                print("Resolved location to: \(coordinate.latitude), \(coordinate.longitude)")
            }
        }
        
        private func saveJournalEntry() {
            guard !userRecordID.isEmpty else {
                showAlert(message: "User is not logged in.")
                return
            }

            guard !journalText.trimmingCharacters(in: .whitespaces).isEmpty else {
                showAlert(message: "Please enter journal text.")
                return
            }

            guard !goalTag.trimmingCharacters(in: .whitespaces).isEmpty else {
                showAlert(message: "Please add a goal tag.")
                return
            }

            guard !relatedPeople.trimmingCharacters(in: .whitespaces).isEmpty else {
                showAlert(message: "Please add related people.")
                return
            }

            guard let selectedLocation = selectedLocation else {
                showAlert(message: "Please select a location.")
                return
            }

            guard !goalAchieved.isEmpty else {
                showAlert(message: "Please indicate whether the goal was achieved.")
                return
            }

            isSaving = true

            let container = CKContainer(identifier: "iCloud.intentsify")
            let database = container.publicCloudDatabase
            let record = CKRecord(recordType: "JournalEntry")

            let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userRecordID), action: .none)
            record["userID"] = userReference
            record["text"] = journalText
            record["entryDate"] = entryDate as NSDate
            record["goalTag"] = goalTag
            record["relatedPeople"] = relatedPeople

            // Save only latitude and longitude
            let locationToSave = CLLocation(latitude: selectedLocation.coordinate.latitude,
                                             longitude: selectedLocation.coordinate.longitude)
            record["location"] = locationToSave // Store location explicitly as CLLocation

            record["goalAchieved"] = goalAchieved

            // Debugging logs
            print("Saving record:")
            print("UserID: \(userRecordID)")
            print("Text: \(journalText)")
            print("Date: \(entryDate)")
            print("GoalTag: \(goalTag)")
            print("RelatedPeople: \(relatedPeople)")
            print("Location: \(locationToSave.coordinate.latitude), \(locationToSave.coordinate.longitude)")
            print("GoalAchieved: \(goalAchieved)")

            database.save(record) { _, error in
                DispatchQueue.main.async {
                    self.isSaving = false
                    if let error = error {
                        self.showAlert(message: "Failed to save: \(error.localizedDescription)")
                        print("Save error: \(error.localizedDescription)")
                    } else {
                        print("Save successful!")
                        self.clearForm()
                        withAnimation {
                            self.showCheckmark = true
                        }
                    }
                }
            }
        }
        
        private func clearForm() {
            journalText = ""
            entryDate = Date()
            goalTag = ""
            relatedPeople = ""
            selectedLocation = nil
            locationQuery = ""
            goalAchieved = ""
        }
    }

    // Helper class for MKLocalSearchCompleter
    class LocationSearchDelegate: NSObject, MKLocalSearchCompleterDelegate {
        private var onUpdate: ([MKLocalSearchCompletion]) -> Void

        init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
            self.onUpdate = onUpdate
        }

        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            onUpdate(completer.results)
        }

        func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
            print("Search completer error: \(error)")
            onUpdate([])
        }
    }
