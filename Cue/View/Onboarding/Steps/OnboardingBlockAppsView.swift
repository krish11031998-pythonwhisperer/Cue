//
//  OnboardingBlockAppsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import SFSafeSymbols

/// Shows distracting apps being shielded during a focus session, then asks for Screen Time access.
struct OnboardingBlockAppsView: View {

    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        OnboardingStepLayout(includeScrollView: false) {
            OnboardingHeader("Block distracting apps\n",
                             accent: "while you focus",
                             subtitle: "Pick the apps that pull you away. Cue locks them until your session ends.")
        } content: {
            VStack(alignment: .center, spacing: 22) {
                OnboardingBlockAppsIllustration()
                    .frame(maxHeight: .infinity)

                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.appBlockingStatus == .denied ? AnyShapeStyle(Color.red) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .contentTransition(.opacity)
            }
            .padding(.top, 24)
            .animation(.easeInOut, value: viewModel.appBlockingStatus)
//        } actions: {
//            OnboardingPermissionActions(status: viewModel.appBlockingStatus,
//                                        isRequesting: viewModel.isRequestingAppBlocking,
//                                        allowTitle: "Allow app blocking",
//                                        onAllow: viewModel.requestAppBlocking,
//                                        onContinue: viewModel.advance,
//                                        onOpenSettings: viewModel.openAppSettings)
        }
        .task {
            viewModel.refreshAppBlockingStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Returning from Settings.
            guard newPhase == .active else { return }
            viewModel.refreshAppBlockingStatus()
        }
    }

    private var explanation: String {
        switch viewModel.appBlockingStatus {
        case .notDetermined:
            return "Uses Apple's Screen Time. Cue never sees which apps you use."
        case .granted:
            return "App blocking is on. Choose apps to block when you start a focus session."
        case .denied:
            return "Screen Time access is off for Cue. Turn it on in Settings to block apps."
        }
    }
}

// MARK: - Illustration

/// A home-screen grid where the distracting apps get locked, over a shield card.
private struct OnboardingBlockAppsIllustration: View {

    private struct AppTile: Identifiable {
        let id: Int
        let symbol: SFSymbol
        let colorName: String
        let blocked: Bool
    }

    private let tiles: [AppTile] = [
        .init(id: 0, symbol: .cameraFill, colorName: "rose", blocked: true),
        .init(id: 1, symbol: .playRectangleFill, colorName: "peach", blocked: true),
        .init(id: 2, symbol: .bookFill, colorName: "leaf", blocked: false),
        .init(id: 3, symbol: .bubbleLeftAndBubbleRightFill, colorName: "aqua", blocked: true),
        .init(id: 4, symbol: .calendar, colorName: "sky", blocked: false),
        .init(id: 5, symbol: .gamecontrollerFill, colorName: "lavender", blocked: true),
        .init(id: 6, symbol: .musicNote, colorName: "honey", blocked: false),
        .init(id: 7, symbol: .cartFill, colorName: "orchid", blocked: true)
    ]

    @State private var locked: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 18) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(56), spacing: 16), count: 4), spacing: 16) {
                ForEach(tiles) { tile in
                    tileView(tile)
                }
            }

            shieldCard
        }
        .padding(18)
        .background(OnboardingPalette.card, in: .rect(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(OnboardingPalette.line, lineWidth: 1.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Example: social and game apps locked during a focus session")
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.snappy(duration: 0.4, extraBounce: 0.1)) {
                locked = true
            }
        }
    }

    private func tileView(_ tile: AppTile) -> some View {
        let isLocked = locked && tile.blocked
        return RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(tile.colorName))
            .frame(width: 56, height: 56)
            .overlay {
                Image(systemSymbol: tile.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .saturation(isLocked ? 0 : 1)
            .opacity(isLocked ? 0.45 : 1)
            .overlay(alignment: .topTrailing) {
                if isLocked {
                    Image(systemSymbol: .lockFill)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(OnboardingPalette.skyInk)
                        .frame(width: 22, height: 22)
                        .background(OnboardingPalette.sky, in: .circle)
                        .offset(x: 6, y: -6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
    }

    private var shieldCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemSymbol: .hourglass)
                .font(.body.weight(.semibold))
                .foregroundStyle(OnboardingPalette.skyInk)
                .frame(width: 36, height: 36)
                .background(OnboardingPalette.sky.opacity(0.35), in: .rect(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("Deep work · 25 min left")
                    .font(.subheadline.weight(.semibold))
                Text("5 apps paused until you're done")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.cueItBackground, in: .rect(cornerRadius: 18, style: .continuous))
    }
}
