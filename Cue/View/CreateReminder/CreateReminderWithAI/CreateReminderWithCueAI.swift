//
//  CreateReminderWithCueAI.swift
//  Cue
//
//  Created by Krishna Venkatramani on 02/03/2026.
//

import SwiftUI
import VanorUI
import Model

struct CreateReminderWithCueAI: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: CueReminderGeneratorViewModel
    @State private var size: CGSize = .zero
    @State private var circleCount: Int = .zero
    @State private var textFieldIsInFocus: Bool = false
    
    init(store: Store) {
        self.viewModel = .init(store: store)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            AnimatedDotView(bubbleAnimation: viewModel.bubbleAnimation)
            switch viewModel.recorderState {
            case .resume, .pause:
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.transribedString + viewModel.volatileTranscribedText)
                            .contentTransition(.opacity)
                            .animation(.easeInOut, value: viewModel.transribedString + viewModel.volatileTranscribedText)
                            .padding(.horizontal, 20)
                        ForEach(Array(viewModel.reminders), id: \.self) { reminder in
                            reminderViewBuilder(reminder: reminder)
                        }
                    }
                    .padding(.top, 24)
                }
            case .stop, .idle:
                if viewModel.reminders.isEmpty {
                    emptyView
                } else {
                    ScrollView(.vertical) {
                        VStack(alignment: .center, spacing: 12) {
                            ForEach(Array(viewModel.reminders), id: \.self) { reminder in
                                reminderViewBuilder(reminder: reminder)
                            }
                        }
                        .padding(.top, 24)
                    }
                }
            }
            
            if textFieldIsInFocus {
                Color.clear
                    .ignoresSafeArea(edges: .all)
                    .onTapGesture {
                    }
            }
        }
        .onPreferenceChange(CueTextFieldFocusPreferenceKey.self, perform: {
            textFieldIsInFocus = $0
        })
//        .alert("", isPresented: .init(get: { self.viewModel.alert != nil }, set: { _ in self.viewModel.alert = nil }), presenting: viewModel.alert, actions: { alert in
//            Button(role: .confirm) {
//                dismiss()
//            }
//        }, message: { alert in
//            Text(alert.message)
//        })
        .task(id: viewModel.recorderState) { [weak viewModel] in
            guard let recorderState = viewModel?.recorderState else { return }
            switch recorderState {
            case .idle:
                break
            case .resume:
                await viewModel?.setupRecorderAndStart()
            case .stop:
                await viewModel?.stopRecorder()
            case .pause:
                viewModel?.pauseRecording()
            }
        }
        .task(id: viewModel.generationState) { [weak viewModel] in
            await viewModel?.generateReminderTask()
        }
        .onDisappear(perform: { [weak viewModel] in
            Task { [weak viewModel] in
                await viewModel?.stopRecorder()
            }
        })
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemSymbol: .checkmark) {
                    Task { @MainActor in
                        #warning("Need to track this reminder Creations")
                        await viewModel.createReminders()
                        dismiss()
                    }
                }
                .tint(Color.proSky.baseColor)
                .buttonStyle(.glassProminent)
                .disabled(!viewModel.createRemindersIsEnabled)
            }
        })
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 0) {
            CueRecordingTextFieldFloatingView(generating: viewModel.isGenerating,
                                              waveformBuilder: nil) { [weak viewModel] in
                viewModel?.recorderState = $0
            } generateReminder: { [weak viewModel] text in
                viewModel?.generationState = .generate(text)
            }

        }
    }
    
    
    // MARK: - View Builder
    
    @ViewBuilder
    private func reminderViewBuilder(reminder: ReminderModel) -> some View {
        ReminderView(model: .init(title: reminder.title,
                                  icon: .init(reminder.icon)!,
                                  theme: Color.proSky,
                                  time: reminder.date,
                                  state: .display,
                                  tags: [],
                                  logReminder: nil,
                                  deleteReminder: { [weak viewModel] in
            viewModel?.reminders.remove(reminder)
        }))
        .padding(.horizontal, 20)
        .id(reminder.title)
        .popInContainer(angle: 0,
                        animation: .snappy)
    }
    
    
    @ViewBuilder
    var emptyView: some View {
        VStack(alignment: .center, spacing: 32) {
            Image(systemSymbol: .sparkles2)
                .font(.system(size: 64, weight: .semibold, design: .default))
                .fontWeight(.semibold)
                .foregroundStyle(Color.proSky.baseColor)
                .symbolEffect(.pulse, options: .repeat(.periodic(5, delay: 10)), isActive: true)
            Text("Create reminder with cue:AI")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.proSky.foregroundTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    CreateReminderWithCueAI(store: .init())
//        .environment(Store())
}
