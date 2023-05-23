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
            HStack {
                Text("Nice Tone")
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity, alignment: .center)
            }.padding()
            FrequencyView()
        }
    }
}

struct FrequencyView: View {
    @State var frequency: Double = 440
    var body: some View {
        VStack{
            TunerView(frequency: $frequency)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

