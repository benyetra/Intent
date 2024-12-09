//
//  CalendarView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationView {
            Text("Calendar View")
                .font(.title)
                .padding()
                .navigationTitle("Calendar")
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}


#Preview {
    CalendarView()
}
