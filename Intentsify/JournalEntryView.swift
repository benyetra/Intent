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
    
    // Journal State
    @State private var journalText: String = ""
    @State private var entryDate: Date = Date()
    @State private var selectedGoal: String = ""
    @State private var goals: [String] = [] // List of goals
    @State private var relatedPeople: String = ""
    @State private var locationQuery: String = ""
    @State private var selectedLocation: CLLocation? = nil
    @State private var goalAchieved: String = ""
    @State private var isLoadingGoals = false

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showCheckmark: Bool = false
    
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
                ScrollView {
                    VStack(spacing: 16) {
                        // Date Picker Section
                        datePickerSection
                        
                        // Journal Text Section
                        journalSection
                        
                        // Goal Tag Section
                        goalPickerSection
                        
                        // Related People Section
                        relationshipSection
                        
                        // Location Search Section
                        locationSearchSection
                        
                        // Goal Achieved Section
                        goalAchievedSection
                        
                        // Submit Button
                        saveButton
                    }
                    .padding()
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Error"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .background(Color("LightBackgroundColor").ignoresSafeArea())
            }
            // Checkmark Animation Overlay
            if showCheckmark {
                checkmarkOverlay
            }
        }
        .onAppear {
            setupSearchCompleter()
            fetchGoals()
            locationManager.requestLocationPermission()
        }
    }

    // MARK: - Date Picker Section
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date and Time")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))
            
            DatePicker(
                "Select Date and Time",
                selection: $entryDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .tint(Color("PrimaryTextColor")) // Updates interactive components
            .colorMultiply(Color("PrimaryTextColor")) // Affects static DatePicker text
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("SecondaryBackgroundColor"))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }


    // MARK: - Journal Section
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

    // MARK: - Goal Picker Section
    private var goalPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a Goal")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("SecondaryBackgroundColor"))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .frame(height: 44)
                
                // Picker with custom label color
                Picker("", selection: $selectedGoal) {
                    Text("Choose a Goal") // Placeholder
                        .foregroundColor(Color("PrimaryTextColor").opacity(0.5))
                        .tag("")
                    
                    ForEach(goals, id: \.self) { goal in
                        Text(goal)
                            .foregroundColor(Color("PrimaryTextColor")) // Apply text color to items
                            .tag(goal)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(Color("PrimaryTextColor")) // Ensure menu tint matches PrimaryTextColor
                .padding(.horizontal, 12)
                .frame(height: 44)
            }
        }
    }


    // MARK: - Related People Section
    private var relationshipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Related People")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))
            
            TextField("Add names of people", text: $relatedPeople)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("SecondaryBackgroundColor"))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(relatedPeople.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 2)
                )
        }
    }

    // MARK: - Location Search Section
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
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(locationQuery.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 2)
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
                                                .foregroundColor(Color("ReverseAccentColor"))
                                            Text(result.subtitle)
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
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

    // MARK: - Goal Achieved Section
    private var goalAchievedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Did you progress this goal?")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))
            
            HStack(spacing: 16) {
                Button(action: { goalAchieved = "true" }) {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(Color("ThumbColorText"))
                        Text("Yes")
                            .foregroundColor(Color("ThumbColorText"))
                    }
                    .padding(8)
                    .foregroundColor(goalAchieved == "true" ? Color("PrimaryTextColor") : .primary)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(goalAchieved == "true" ? Color("AccentTextColor") : Color("SecondaryBackgroundColor"))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                }
                
                Button(action: { goalAchieved = "false" }) {
                    HStack {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundColor(Color("ThumbColorText"))
                        Text("No")
                            .foregroundColor(Color("ThumbColorText"))
                    }
                    .padding(8)
                    .foregroundColor(goalAchieved == "false" ? .white  : .primary)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(goalAchieved == "false" ? Color("ErrorColor") : Color("SecondaryBackgroundColor"))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Ensures alignment with other fields
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveJournalEntry) {
            if isSaving {
                ProgressView().tint(.white)
            } else {
                Text("Save Journal")
                    .foregroundColor(Color("ReverseAccentColor"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("AccentColor"))
        .cornerRadius(8)
    }

    // MARK: - Checkmark Overlay
    private var checkmarkOverlay: some View {
        ZStack {
            Color("SplashColor").opacity(0.4).ignoresSafeArea()
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(Color("AccentColor"))
                    .transition(.scale) // Smooth transition when it appears/disappears
                    .animation(.easeInOut(duration: 0.5), value: showCheckmark)
                Text("Entry Saved!")
                    .font(.headline)
                    .transition(.opacity) // Fade out text smoothly
            }
        }
    }

    // MARK: - Helper Functions
    private func setupSearchCompleter() {
        let delegate = LocationSearchDelegate { results in
            self.searchResults = results
        }
        searchCompleter.delegate = delegate
        locationSearchDelegate = delegate
    }
    
    //MARK: Show Alert
    private func showAlert(message: String) {
                alertMessage = message
                showAlert = true
            }
    //MARK: Resolve Location
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
            self.searchResults = [] // Clear search results to dismiss the list
            print("Resolved location to: \(coordinate.latitude), \(coordinate.longitude)")
        }
    }
    
    // MARK: - Fetch Goals from CloudKit
    private func fetchGoals() {
        guard !userRecordID.isEmpty else { return }

        isLoadingGoals = true
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let userRecordID = CKRecord.ID(recordName: self.userRecordID)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)

        let predicate = NSPredicate(format: "userID == %@", userReference)
        let query = CKQuery(recordType: "JournalEntry", predicate: predicate)

        database.perform(query, inZoneWith: nil) { results, error in
            DispatchQueue.main.async {
                isLoadingGoals = false
                if let records = results {
                    self.goals = Array(Set(records.compactMap { $0["goalTag"] as? String }))
                }
            }
        }
    }
    
    //MARK: Save Journal Entry
    private func saveJournalEntry() {
        guard !userRecordID.isEmpty else {
            showAlert(message: "User is not logged in.")
            return
        }

        guard !journalText.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "It looks like you forgot to enter your description!")
            return
        }

        guard !selectedGoal.isEmpty else {
            showAlert(message: "Don't forget to select a goal.")
            return
        }

        guard !relatedPeople.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please add the people related to this goal.")
            return
        }

        guard let selectedLocation = selectedLocation else {
            showAlert(message: "Enter a location where this event happened.")
            return
        }

        guard !goalAchieved.isEmpty else {
            showAlert(message: "Please add if you progressed your goal or not.")
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
        record["goalTag"] = selectedGoal
        record["relatedPeople"] = relatedPeople

        let locationToSave = CLLocation(latitude: selectedLocation.coordinate.latitude,
                                         longitude: selectedLocation.coordinate.longitude)
        record["location"] = locationToSave

        record["goalAchieved"] = goalAchieved

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
                    
                    // Dismiss the checkmark animation after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            self.showCheckmark = false
                        }
                    }
                }
            }
        }
    }

    //MARK: Clear Form
    private func clearForm() {
        journalText = ""
        entryDate = Date()
        selectedGoal = ""
        relatedPeople = ""
        selectedLocation = nil
        locationQuery = ""
        goalAchieved = ""
    }
}

// MARK: - LocationSearchDelegate
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
