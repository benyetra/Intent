//
//  JournalEntryView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

struct JournalEntryView: View {
    var body: some View {
        NavigationView {
            Text("Journal Entry View")
                .font(.title)
                .padding()
                .navigationTitle("Journal")
        }
    }
}

struct JournalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        JournalEntryView()
    }
}


#Preview {
    JournalEntryView()
}
