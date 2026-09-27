//
//  RoutineStepsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/09/2026.
//

import SwiftUI
import Model
import VanorUI

// MARK: - StepsView

public struct RoutineStepsView: ConfigurableView {
    
    public struct Step: Hashable, Identifiable {
        let icon: Icon
        let title: String
        
        public var id: String {
            "\(title)_\(icon.hashValue)"
        }
    }
    
    public struct Config: Hashable {
        let steps: [Step]
        let color: Color
    }
    
    let config: Config
    
    public init(model: Config) {
        self.config = model
    }
    
    var theme: LCHColor {
        .init(color: config.color)
    }
    
    struct DashLine: Shape {
        nonisolated func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: rect.origin)
                path.addLine(to: .init(x: rect.minX, y: rect.maxY))
            }
            .strokedPath(.init(lineWidth: rect.width, lineCap: .round, lineJoin: .round, dash: [2, 4], dashPhase: 0.5))
        }
    }
    
    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(config.steps) { step in
                    HStack(alignment: .center, spacing: 8) {
                        ReminderIconView(icon: step.icon,
                                         foregroundColor: .clear,
                                         backgroundColor: theme.backgroundTertiary,
                                         font: .headline)
                            .frame(width: 32, height: 32, alignment: .center)
                            
                        Text(step.title)
                            .font(.headline)
                    }
                }
            }
            .background(alignment: .leading) {
                DashLine()
                    .fill(theme.surfacePrimary)
                    .frame(width: 2)
                    .padding(.leading, 16)
                    .padding(.vertical, 16)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Subtasks".uppercased())
                    .font(.bitcountMedium(style: .footnote))
                    .foregroundStyle(.secondary)
                Text("\(config.steps.count)")
                    .font(.bitcountMedium(style: .largeTitle))
            }
            
        }
        .groupBoxStyle(RoutineDetailGroupBox(style: .default))
    }
    
    public static var viewName: String { "RoutineStepsView" }
}
