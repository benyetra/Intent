//
//  TrendsView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

struct TrendsView: View {
    var body: some View {
        NavigationView {
            Text("Trends View")
                .font(.title)
                .padding()
                .navigationTitle("Trends")
        }
    }
}

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        TrendsView()
    }
}


#Preview {
    TrendsView()
}
