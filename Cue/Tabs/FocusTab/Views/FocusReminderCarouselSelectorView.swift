//
//  FocusReminderCarouselSelectorView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 31/05/2026.
//

import SwiftUI
import VanorUI
import Model

extension ReminderModel: Identifiable {
    public var id: String {
        title
    }
}

struct FocusReminderCarouselSelectorView: View {
    
    static let itemSize: CGSize = .init(width: 72, height: 72)
    let selectedItem: FocusTimerRootViewModel.TimerType?
    let items: [FocusTimerRootViewModel.TimerType]
    @State private var scrollContainerSize: CGSize = .zero
    
    var body: some View {
        CentralizeItemCarousel(selectedItem: selectedItem, itemSize: Self.itemSize, items: items) { item in
            itemBubbleBuilder(icon: item.icon, selected: selectedItem == item)
        }
        .frame(height: Self.itemSize.height)
        .scrollIndicators(.hidden)
    }
    
    
    @ViewBuilder
    private func reminderBubbleBuilder(_ reminder: ReminderModel) -> some View {
        let selected = reminder.id == selectedItem?.id
        itemBubbleBuilder(icon: .init(reminder.icon)!, selected: selected)
    }
    
    @ViewBuilder
    private func itemBubbleBuilder(icon: Icon, selected: Bool) -> some View {
        let backgroundColor: Color = selected ? Color.proSky.surfaceSecondary : Color.surfaceTertiary
        ReminderIconView(icon: icon,
                         foregroundColor: .primary,
                         backgroundColor: backgroundColor,
                         font: .largeTitle)
        .overlay(alignment: .center) {
            if selected {
                Circle()
                    .fill(Color.clear)
                    .stroke(Color.proSky.outlineTertiary, lineWidth: 2)
            }
        }
        .padding(.all, 4)
        .frame(width: Self.itemSize.width, height: Self.itemSize.height, alignment: .center)
    }
}


#Preview {
    @Previewable @State var selectedItem: FocusTimerRootViewModel.TimerType?

    FocusReminderCarouselSelectorView(selectedItem: selectedItem, items: [.exampleOne(), .exampleTwo(), .exampleThree(), .exampleFour()].map { .reminder($0) })
        .border(Color.red, width: 2)
        .task { @MainActor in
            selectedItem = .reminder(.exampleFour())
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeInOut) {
                selectedItem = .focus
            }
        }
}
