//
//  CreateImagePlaygroundImage.swift
//  Cue
//
//  Created by Krishna Venkatramani on 03/09/2026.
//

import SwiftUI
import ImagePlayground
import VanorUI

fileprivate extension ImagePlaygroundStyle {
    
    var title: String? {
        switch self {
        case .animation:
            return "Animation"
        case .emoji:
            return "Any"
        case .illustration:
            return "Illustration"
        case .sketch:
            return "Sketch"
        default:
            return nil
        }
    }
    
}

struct ImagePlaygroundConfigurationEditor: View {
    @Environment(\.dismiss) var dismiss
    @Binding var imagePlaygroundStyle: ImagePlaygroundStyle
    @Binding var concept: String
    var createImage: () -> Void
    
    private func tintColor(for playgroundStyle: ImagePlaygroundStyle) -> Color {
        if imagePlaygroundStyle == playgroundStyle {
            return Color.proSky.baseColor
        } else {
            return Color.proSky.surfaceSecondary
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            TextField("", text: $concept)
                .font(.title2.weight(.semibold))
                .limitText(textLimit: 30, text: $concept)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
                .padding(.bottom, 24)
            
            OverFlowingHorizontalLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(ImagePlaygroundStyle.all) { imagePlaygroundStyle in
                    if let title = imagePlaygroundStyle.title {
                        Button(title) {
                            self.imagePlaygroundStyle = imagePlaygroundStyle
                        }
                        .tint(tintColor(for: imagePlaygroundStyle))
                        .buttonStyle(.glassProminent)
                        .controlSize(.regular)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 32) {
            Button {
                dismiss()
                createImage()
            } label: {
                Text("Create")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
    }
}
