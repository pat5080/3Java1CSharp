//
//  GaugeView.swift
//  NiceTone
//
//  Created by Wai Yan Seto on 15/5/2023.
//

import Foundation
import SwiftUI

struct GaugeStyleView: GaugeStyle{
    private var gradient = AngularGradient(gradient: Gradient(colors: [.red, .green, .red]), center: .center, startAngle: .degrees(180), endAngle: .degrees(360))
    
    func makeBody(configuration: Configuration) -> some View {
        VStack {
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
            .frame(height: 100)
            HStack {
                configuration.minimumValueLabel
                Spacer()
                configuration.currentValueLabel
                Spacer()
                configuration.maximumValueLabel
            }
        }
        .frame(width: 300, height: 300)
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
