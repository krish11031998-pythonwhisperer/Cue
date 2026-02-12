//
//  CreateTagView.swift
//  Model
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import Foundation
import SwiftUI
import VanorUI
import Model

struct CreateTagView: View {
    
    @State private var viewModel: CreateTagViewModel = .init()
    @FocusState var textFieldIsFocused
    @Environment(\.dismiss) var dismiss
    let createTag: (String, Color) -> Void
    
    init(createTag: @escaping (String, Color) -> Void) {
        self.createTag = createTag
    }
    
    private let allColors: [Color] = {
        Color.allProHues.keys.sorted().compactMap { Color.allProHues[$0]?.baseColor }
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                Text(createTagAttributesString)
                    .padding(.bottom, 16)
                    .padding(.top, 20)
                
                HStack(alignment: .center, spacing: 8) {
                    Circle()
                        .fill(viewModel.color)
                        .frame(width: 32, height: 32, alignment: .center)
                    
                    TextField("Work",
                              text: $viewModel.tagName,
                              axis: .vertical)
                    .font(.title3)
                    .fontWeight(.medium)
                    .submitLabel(.go)
                    .focused($textFieldIsFocused)
                    .autoDismissOnReturn(text: $viewModel.tagName) {
                        self.textFieldIsFocused = false
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 8) {
                    ForEach(allColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32, alignment: .center)
                            .onTapGesture {
                                viewModel.color = color
                            }
                    }
                }
                .padding(.all, 20)
            }
            .scrollIndicators(.hidden)
            
            CueLargeButton {
                createTag(viewModel.tagName, viewModel.color)
                dismiss()
            } content: {
                Text("Create Tag")
                    .font(.headline)
            }
            .disabled(viewModel.tagName.isEmpty)

        }
    }
    
    var createTagAttributesString: AttributedString {
        var attributed = AttributedString("Create a ", attributes: .init([.font: UIFont.preferredFont(for: .headline, weight: .semibold)]))
        let tag = AttributedString("Tag", attributes: .init([.font: UIFont.preferredFont(for: .headline), .foregroundColor: viewModel.color.baseColor.asUIColor]))
        attributed.append(tag)
        return attributed
    }
}

fileprivate struct TestView: View {
    
    @State private var presentSheet: Bool = false
    
    var body: some View {
        ZStack(alignment: .center) {
            Button("Create Tag") {
                presentSheet.toggle()
            }
            .tint(.accentColor)
            .buttonStyle(.glassProminent)
        }
        .sheet(isPresented: $presentSheet) {
            CreateTagView { _, _ in
                print("Create tag")
            }
            .fittedPresentationDetent()
        }
    }
}


#Preview {
    TestView()
}
