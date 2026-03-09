//
//  WaveFormsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 04/04/2026.
//

import SwiftUI
import VanorUI

struct WaveformBar: Identifiable {
    let id: UUID
    let value: CGFloat
    let color: Color
    
    init(id: UUID = .init(), value: CGFloat) {
        self.id = id
        self.value = value
        switch value {
        case 0..<0.21:
            color = Color.secondarySystemBackground
        case 0.21..<0.5:
            color = Color.proSky.surfaceSecondary
        case 0.5..<0.7:
            color = Color.proSky.surfacePrimary
        default:
            color = Color.proSky.baseColor
        }
    }
}

@MainActor
@Observable
class WaveformViewModel {
    
    static var maxBars: Int = 600
    var bars: [WaveformBar] = []
    
    func append(_ values: [CGFloat]) {
        guard !values.isEmpty else { return }
        var newBars: [WaveformBar] = bars
        newBars.append(contentsOf: values.map { WaveformBar(value: max($0, 0.02)) })
        
        if newBars.count > Self.maxBars {
            newBars.removeFirst(bars.count - Self.maxBars/2)
        }
        
        bars = newBars
    }
    
    func reset() {
        bars.removeAll()
    }
}


struct WaveformView: View {
    
    @State private var viewModel: WaveformViewModel = .init()
    private let waveformBufferStream: AsyncStream<[CGFloat]>?
    let barWidth: CGFloat = 3
    let spacing: CGFloat = 2
    let maxHeight: CGFloat = 56
    
    init(waveformBufferStream: AsyncStream<[CGFloat]>?) {
        self.waveformBufferStream = waveformBufferStream
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: spacing) {
                    ForEach(viewModel.bars) { bar in
                        Capsule()
                            .frame(
                                width: barWidth,
                                height: max(4, bar.value * maxHeight)
                            )
                            .id(bar.id)
                    }
                }
                .frame(height: maxHeight)
                .padding(.horizontal, 12)
            }
            .onChange(of: viewModel.bars.last?.id) { _, newID in
                guard let newID else { return }
                proxy.scrollTo(newID, anchor: .trailing)
            }
        }
        .frame(height: maxHeight + 12)
        .task(id: waveformBufferStream != nil) { [weak viewModel] in
            if let waveformBufferStream {
                for await values in waveformBufferStream {
                    viewModel?.append(values)
                }                
            }
        }
    }
    
}
