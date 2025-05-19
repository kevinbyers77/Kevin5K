//
//  StartDateView.swift
//  Kevin5K
//
//  Created by Kevin Byers on 2/5/2025.
//


import SwiftUI

struct StartDateView: View {
    @EnvironmentObject var store: SessionStore
    @State private var startDate = Calendar.current.startOfDay(for: .now)
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Choose your start date")
                .font(.title2)
            
            DatePicker("Start", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
            
            Button("Create Plan") { store.initialise(from: startDate) }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}