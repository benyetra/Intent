//
//  SplashScreenView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/16/24.
//


import SwiftUI

struct SplashScreenView: View {
    // Animation state variables
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background Color
            Color(Color("SplashColor"))
                .edgesIgnoringSafeArea(.all)
            
            ZStack {
                // Pulsating Glow Ring
                Circle()
                    .stroke(lineWidth: 6) // Thinner ring
                    .foregroundColor(Color("AccentColor").opacity(0.3)) // Ring color
                    .frame(width: 150, height: 150) // Make the circle smaller
                    .scaleEffect(isAnimating ? 2.1 : 1.0) // Subtle pulsating scale
                    .opacity(isAnimating ? 0.4 : 0.6) // Vary opacity for glow effect
                    .animation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // App Icon (Your leaf design)
                Image("leaf_icon") // Replace with your image asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180) // Smaller size for the icon
            }
        }
        .onAppear {
            // Start the animation
            isAnimating = true
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
