//
//  CueAIView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 02/03/2026.
//

import SwiftUI
import VanorUI
import Model

struct CueAIView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel: CueAIViewModel
    @State private var size: CGSize = .zero
    @State private var circleCount: Int = .zero
    @State private var textFieldIsInFocus: Bool = false
    
    init(store: Store) {
        self.viewModel = .init(store: store)
    }
    
    var gradientStops: [Gradient.Stop] {
        let colors: [Color]
        let stops: [CGFloat]
        if colorScheme == .light {
            colors = [.waveformColorOne, .waveformColorTwo, .waveformColorThree]
            stops = [0.17, 0.58, 1]
        } else {
            colors = [.waveformDarkColorOne.opacity(0.75), .waveformDarkColorTwo, .waveformDarkColorThree, .waveformDarkColorFour]
            stops = [0.14, 0.37, 0.72, 1]
        }
        
        return zip(colors, stops).map {
            Gradient.Stop(color: $0, location: $1)
        }
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            
            WaveformBubbleView(gradientStops: gradientStops)
                .ignoresSafeArea(edges: .all)
            
            VStack(alignment: .leading, spacing: 10) {
                switch viewModel.recorderState {
                case .resume, .pause:
                    Text(viewModel.transribedString + viewModel.volatileTranscribedText)
                        .contentTransition(.opacity)
                        .animation(.easeInOut, value: viewModel.transribedString + viewModel.volatileTranscribedText)
                        .padding(.horizontal, 20)
                case .idle, .stop:
                    EmptyView()
                }
                
                ReminderScrollView(viewModel: viewModel)
            }
            
            if textFieldIsInFocus {
                Color.red.opacity(0.2)
                    .ignoresSafeArea(edges: .all)
                    .onTapGesture {
                        self.textFieldIsInFocus = false
                    }
            }
        }
        .onPreferenceChange(CueTextFieldFocusPreferenceKey.self, perform: {
            textFieldIsInFocus = $0
        })
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
        #if !AI_TAB
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button("", systemSymbol: .xmark) {
                    dismiss()
                }
            }

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
        #endif
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 0) {
            CueRecordingTextFieldFloatingView(generating: viewModel.isGenerating,
                                              canSaveGenerated: !viewModel.reminders.isEmpty,
                                              waveformBuilder: nil) { [weak viewModel] in
                viewModel?.recorderState = $0
            } generateReminder: { [weak viewModel] text in
                viewModel?.generationState = .generate(text)
            }
            #if AI_TAB
            .padding(.bottom, 20)
            #endif
        }
        .sheet(item: $viewModel.presentation, content: { presentation in
            switch presentation {
            case .editReminder(let reminderModel, let editAction):
                NewCreateReminderView(mode: .editFromAI(reminderModel, editAction), store: viewModel.store)
            }
        })
        .environment(viewModel.voiceTranscriber.audioWaveformManager)
    }
    
    
    // MARK: - ReminderScrollView
    
    struct ReminderScrollView: View {
        var viewModel: CueAIViewModel

        var body: some View {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.reminders, id: \.id) { reminderModel in
                        ReminderCard(id: reminderModel.id, reminder: reminderModel.reminder) {
                            viewModel.remove(reminderModel)
                        } edit: {
                            viewModel.edit(reminderModel)
                        }
                    }
                }
                .padding(.top, 24)
            }
            .scrollEdgeEffectStyle(.soft, for: .bottom)
        }
    }
    
    // MARK: - View Builder
    
    struct ReminderCard: View, Equatable {
        
        let id: UUID
        let reminder: ReminderModel
        let remove: () -> Void
        let edit: () -> Void
        
        var body: some View {
            ReminderView(model: .init(title: reminder.title, icon: .init(reminder.icon)!,
                                      lightColor: reminder.color.resolved(for: .light),
                                      darkColor: reminder.color.resolved(for: .dark),
                                      time: reminder.schedule?.timeScheduled ?? reminder.date,
                                      state: .showDisplayOptions(delete: remove, edit: edit), tags: [], logReminder: nil, deleteReminder: nil))
            .padding(.horizontal, 20)
            .id(reminder)
            .popInContainer(angle: .random(in: -0.5..<0.5),
                            animation: .snappy)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.reminder == rhs.reminder
        }
        
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
    CueAIView(store: .init())
//        .environment(Store())
}
