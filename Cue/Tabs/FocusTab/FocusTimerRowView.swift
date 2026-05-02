//
//  FocusTimerRowView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/04/2026.
//

import Foundation
import SwiftUI
import VanorUI

public struct FocusTimerRowView: View {
    
    public struct Model: Hashable {
        let image: UIImage
        let title: String
        let icon: Icon
        let duration: TimeInterval
        
        static func example() -> Self {
            .init(image: .solidColor(color: .red.withAlphaComponent(0.4)), title: "Study Focus", icon: .emoji(.init("🧠")), duration: 15 * 60)
        }
    }
    
    public let model: Model
    
    public var body: some View {
        ZStack(alignment: .center) {
            Image(uiImage: model.image)
                .resizable()
                .scaledToFill()
            
            LinearGradient(stops: [.init(color: .black.opacity(0.5), location: 0), .init(color: .black.opacity(0.375), location: 0.2), .init(color: .black.opacity(0), location: 1)], startPoint: .leading, endPoint: .trailing)
            
            VStack(alignment: .leading, spacing: 8) {
                
                ReminderIconView(icon: model.icon,
                                 foregroundColor: .white,
                                 backgroundColor: Color.gray,
                                 font: .caption2)
                .frame(width: 32, height: 32, alignment: .center)
                .fixedSize(horizontal: true, vertical: false)
                
                model.title
                    .headline(color: .white)
                    .asText()
                
                model.duration.timerDurationString
                    .subheadline(color: UIColor.systemGray4, weight: .semibold)
                    .asText()
                
                Spacer()
                
                Label("Start Timer", systemSymbol: .playFill)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.init(.init(vertical: 8, horizontal: 10)))
                    .background(.black, in: .capsule)
            }
            .padding(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .glassEffect(.regular, in: .roundedRect(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    FocusTimerRowView(model: .example())
        .aspectRatio(0.75, contentMode: .fit)
        .containerRelativeFrame(.horizontal) { width, _ in
            width * 0.375
        }
}
