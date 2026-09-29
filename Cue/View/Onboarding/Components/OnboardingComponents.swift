//
//  OnboardingComponents.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import SFSafeSymbols
import VanorUI

// MARK: - Palette

/// Tokens from the onboarding wireframes that aren't in `Colors.xcassets`.
enum OnboardingPalette {
    static let sky: Color = Color("sky")
    static let skyInk: Color = .dynamic(light: 0x1E4C63, dark: 0xCDE9F6)
    static let card: Color = .dynamic(light: 0xFFFFFF, dark: 0x2A2927)
    static let line: Color = .dynamic(light: 0xE6E3D6, dark: 0x3C3B37)
    static let dot: Color = .dynamic(light: 0xDAD7C9, dark: 0x4A4944)
    static let checkOutline: Color = .dynamic(light: 0xD8D4C6, dark: 0x55534D)
    static let mutedFill: Color = .dynamic(light: 0xDCD9CB, dark: 0x3F3E3A)
    static let mutedInk: Color = .dynamic(light: 0x8C8880, dark: 0x9A958E)
    static let aiInk: Color = .dynamic(light: 0x8A2E58, dark: 0xF2A3C7)
    
    static let cardRadius: CGFloat = 24
}

fileprivate extension Color {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

fileprivate extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }
}


fileprivate struct ProgressBar: Shape {
    
    @Environment(\.theme) var theme
    var pct: CGFloat
    
    var animatableData: CGFloat {
        get { pct }
        set { pct = newValue }
    }
    
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            let cornerRadius = rect.size.smallDim
            path.addRoundedRect(in: .init(origin: rect.origin, size: .init(width:  max(cornerRadius, rect.width * pct), height: rect.height)), cornerRadii: .init(topLeading: cornerRadius.half, bottomLeading: cornerRadius.half, bottomTrailing: cornerRadius.half, topTrailing: cornerRadius.half))
        }
    }
    
}

// MARK: - Top Bar

/// Back chevron, progress dots and Skip — shown on every step.
struct OnboardingTopBar: View {
    
    @Environment(\.theme) var theme
    
    let step: OnboardingStep
    let onBack: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ZStack(alignment: .center) {
            if step.showsBack {
                Button(action: onBack) {
                    Image(systemSymbol: .chevronBackward)
                        .font(.headline)
                        .frame(width: 36, height: 36, alignment: .center)
                        .padding(.all, 6)
                        .glassEffect(.regular.interactive(), in: .circle)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.blurReplace)
            }
            
            HStack(alignment: .center, spacing: 6) {
                ForEach(0..<OnboardingStep.progressCount, id: \.self) { index in
                    let isOn = index <= step.progressIndex
                    ZStack(alignment: .center) {
                        ProgressViewShape(pct: 1)
                            .fill(theme.backgroundPrimary)
                        ProgressViewShape(pct: isOn ? 1 : 0)
                            .fill(theme.baseColor)
                            .mask(alignment: .center) {
                                ProgressViewShape(pct: 1)
                                    .fill(Color.black)
                            }
                    }
                    .frame(width: 32, height: 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(step.progressIndex + 1) of \(OnboardingStep.progressCount)")
        }
        .frame(height: 24)
        .animation(.snappy, value: step)
    }
}

// MARK: - Header

struct OnboardingHeader: View {
    
    let title: Text
    let subtitle: String?
    var alignment: HorizontalAlignment = .leading
    
    init(title: Text, subtitle: String? = nil, alignment: HorizontalAlignment = .leading) {
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
    }
    
    init(_ title: String, accent: String? = nil, subtitle: String? = nil, alignment: HorizontalAlignment = .leading) {
        let text: Text
        if let accent {
            text = Text("\(Text(title))\(Text(accent).foregroundStyle(OnboardingPalette.skyInk))")
        } else {
            text = Text(title)
        }
        self.init(title: text, subtitle: subtitle, alignment: alignment)
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 10) {
            title
                .font(.title.weight(.semibold))
                .tracking(-0.5)
            
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(alignment == .center ? .center : .leading)
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Buttons

/// Full-width sky capsule. Turns muted while disabled.
struct OnboardingPrimaryButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.init(top: 14, leading: 20, bottom: 14, trailing: 20))
            .frame(minHeight: 56)
            .foregroundStyle(.white)
            .glassEffect(.regular.interactive(true).tint(Color.proSky.baseColor))
            .contentShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut, value: isEnabled)
    }
}

/// Text-only escape hatch under the primary button ("Maybe later").
struct OnboardingSecondaryButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == OnboardingPrimaryButtonStyle {
    static var onboardingPrimary: OnboardingPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == OnboardingSecondaryButtonStyle {
    static var onboardingSecondary: OnboardingSecondaryButtonStyle { .init() }
}


// MARK: - Step Layout

/// Header on top, scrollable content in the middle, actions pinned to the bottom.
struct OnboardingStepLayout<Header: View, Content: View>: View {
    
    let includeScrollView: Bool
    let header: Header
    let content: Content
    
    init(includeScrollView: Bool,
         @ViewBuilder header: () -> Header,
         @ViewBuilder content: () -> Content) {
        self.includeScrollView = includeScrollView
        self.header = header()
        self.content = content()
    }
    
    var body: some View {
        if includeScrollView {
            ScrollView(.vertical) {
                VStack(alignment: .center, spacing: 0) {
                    header
                        .padding(.top, 28)
                    
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .vertical)
            
        } else {
            VStack(alignment: .center, spacing: 0) {
                header
                    .padding(.top, 28)
                
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}
