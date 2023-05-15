//
//  MainView.swift
//  NiceTone
//
//  Created by Manav Sharma on 15/5/2023.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        VStack {
            Text("Select frequency:")
            FrequencyView()
        }
    }
}

struct FrequencyView: View {
    @State var frequency: Double = 440
    var body: some View {
        HStack {
            Button("Reset", action: {
                frequency = 440
            })
            Button(action: {
                if frequency > 440 {
                    frequency -= 1
                }
            }) {
                Image(systemName: "minus.circle")
            }
            
            Text("\(String(format: "%.2f", frequency)) Hz")
            
            Button(action: {
                frequency += 1
            }) {
                Image(systemName: "plus.circle")
            }
        }
        TunerView(frequency: $frequency)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

