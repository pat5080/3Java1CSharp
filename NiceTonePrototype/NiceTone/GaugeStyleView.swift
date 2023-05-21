//
//  GaugeView.swift
//  NiceTone
//
//  Created by Wai Yan Seto on 15/5/2023.
//

import Foundation
import SwiftUI

struct GaugeStyleView: GaugeStyle{
    public var gradient = AngularGradient(gradient: Gradient(colors: [.red, .green, .red]), center: .center, startAngle: .degrees(180), endAngle: .degrees(360))
    
    let notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    let freq = [261.0, 277.0, 293.0, 311.0, 329.0, 349.0, 370.0, 392.0, 415.0, 440.0, 466.0, 493.0]
    
    @Binding var targetFrequency: Double
    @Binding var targetNote: String
    
    func makeBody(configuration: Configuration) -> some View {
            VStack(alignment: .customCenter) {
                Text("Target")
                    .font(.system(size: 30)).bold()
                HStack {
                    Button(action: {
                        targetFrequency = setCurrentFrequency(note: targetNote)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    Button(action: {
                        if targetFrequency > setCurrentFrequency(note: targetNote) {
                            targetFrequency -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle")
                    }
                    
                    Text("\(String(format: "%.2f", targetFrequency))")
                        .font(.system(size: 30))
                        .alignmentGuide(.customCenter) {
                            $0[HorizontalAlignment.center]
                        }
                    Text("Hz")
                        .font(.title3)
                    
                    Button(action: {
                        targetFrequency += 1
                    }) {
                        Image(systemName: "plus.circle")
                    }
                }
            ZStack() {
                configuration.label
                Arc()
                    .stroke(gradient, lineWidth: 7)
                Rectangle()
                    .foregroundColor(.red)
                    .frame(width: 3, height: 115)
                    .rotationEffect(.degrees((configuration.value - 0.5) * 180), anchor: .bottom)
                Arc()
                    //.trim(from: 0, to: 0.75)
                    .stroke(Color.black, style: StrokeStyle(lineWidth: 7, lineCap: .butt, lineJoin: .round, dash: [3, 36], dashPhase: 0.0))
                    //.rotationEffect(.degrees(180))
            }
            .frame(height: 150)
            HStack {
                configuration.minimumValueLabel
                Spacer()
                configuration.currentValueLabel
                Spacer()
                configuration.maximumValueLabel
            }
        }
        .frame(width: 300, height: 280)
    }
}


struct Arc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = max(rect.size.width, rect.size.height) / 2
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),
                    radius: radius,
                    startAngle: .zero,
                    endAngle: .degrees(180),
                    clockwise: true)
        return path
    }
}
