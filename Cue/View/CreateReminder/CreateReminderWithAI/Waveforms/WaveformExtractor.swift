//
//  WaveformExtractor.swift
//  Cue
//
//  Created by Krishna Venkatramani on 04/04/2026.
//

import AVFoundation
import SwiftUI

enum WaveformExtractor {
    
    /// Converts a PCM buffer into normalized waveform bars.
    /// - Parameters:
    ///   - buffer: Incoming audio buffer from your engine/tap.
    ///   - samplesPerBar: How many PCM frames are grouped into one visual bar.
    ///   - useRMS: true = smoother waveform, false = peak waveform.
    static func makeBars(
        from buffer: AVAudioPCMBuffer,
        samplesPerBar: Int = 256,
        useRMS: Bool = true
    ) -> [CGFloat] {
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return [] }
        
        // Prefer float channel data when available.
        if let floatData = buffer.floatChannelData {
            let channelCount = Int(buffer.format.channelCount)
            return extractFromFloatChannels(
                floatData,
                channelCount: channelCount,
                frameLength: frameLength,
                stride: Int(buffer.stride),
                samplesPerBar: samplesPerBar,
                useRMS: useRMS
            )
        }
        
        // Fallback for Int16 PCM.
        if let int16Data = buffer.int16ChannelData {
            let channelCount = Int(buffer.format.channelCount)
            return extractFromInt16Channels(
                int16Data,
                channelCount: channelCount,
                frameLength: frameLength,
                stride: Int(buffer.stride),
                samplesPerBar: samplesPerBar,
                useRMS: useRMS
            )
        }
        
        return []
    }
    
    private static func extractFromFloatChannels(
        _ data: UnsafePointer<UnsafeMutablePointer<Float>>,
        channelCount: Int,
        frameLength: Int,
        stride: Int,
        samplesPerBar: Int,
        useRMS: Bool
    ) -> [CGFloat] {
        guard channelCount > 0 else { return [] }
        
        var bars: [CGFloat] = []
        bars.reserveCapacity(max(1, frameLength / max(samplesPerBar, 1)))
        
        var start = 0
        while start < frameLength {
            let end = min(start + samplesPerBar, frameLength)
            
            var accumulator: Float = 0
            var peak: Float = 0
            var count = 0
            
            for frame in start..<end {
                var mono: Float = 0
                
                for ch in 0..<channelCount {
                    mono += abs(data[ch][frame * stride])
                }
                mono /= Float(channelCount)
                
                if useRMS {
                    accumulator += mono * mono
                } else {
                    peak = max(peak, mono)
                }
                count += 1
            }
            
            let rawValue: Float
            if useRMS {
                rawValue = count > 0 ? sqrt(accumulator / Float(count)) : 0
            } else {
                rawValue = peak
            }
            
            // Clamp to a visible normalized range
            let normalized = CGFloat(min(max(rawValue, 0), 1))
            bars.append(normalized)
            
            start = end
        }
        
        return bars
    }
    
    private static func extractFromInt16Channels(
        _ data: UnsafePointer<UnsafeMutablePointer<Int16>>,
        channelCount: Int,
        frameLength: Int,
        stride: Int,
        samplesPerBar: Int,
        useRMS: Bool
    ) -> [CGFloat] {
        guard channelCount > 0 else { return [] }
        
        let scale: Float = 1.0 / Float(Int16.max)
        var bars: [CGFloat] = []
        bars.reserveCapacity(max(1, frameLength / max(samplesPerBar, 1)))
        
        var start = 0
        while start < frameLength {
            let end = min(start + samplesPerBar, frameLength)
            
            var accumulator: Float = 0
            var peak: Float = 0
            var count = 0
            
            for frame in start..<end {
                var mono: Float = 0
                
                for ch in 0..<channelCount {
                    mono += Float(abs(data[ch][frame * stride])) * scale
                }
                mono /= Float(channelCount)
                
                if useRMS {
                    accumulator += mono * mono
                } else {
                    peak = max(peak, mono)
                }
                count += 1
            }
            
            let rawValue: Float
            if useRMS {
                rawValue = count > 0 ? sqrt(accumulator / Float(count)) : 0
            } else {
                rawValue = peak
            }
            
            let normalized = CGFloat(min(max(rawValue, 0), 1))
            bars.append(normalized)
            
            start = end
        }
        
        return bars
    }
}
