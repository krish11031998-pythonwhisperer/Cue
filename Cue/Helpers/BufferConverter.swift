//
//  BufferConverter.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/03/2026.
//

import Foundation
import AVFoundation

class BufferConverter {
    enum Error: Swift.Error {
        case failedToCreateConverter
        case failedToCreateConversionBuffer
        case conversionFailed(NSError?)
    }
    
    private var converter: AVAudioConverter?
    nonisolated static func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format
        guard inputFormat != format else {
            return buffer
        }
        
        let converter = AVAudioConverter(from: inputFormat, to: format)
        
        guard let converter else {
            throw Error.failedToCreateConverter
        }
        converter.primeMethod = .none
        
        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.up))
        guard let conversionBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: frameCapacity) else {
            throw Error.failedToCreateConversionBuffer
        }
        
        var nsError: NSError?
        var bufferProcessed = false
        
        let status = converter.convert(to: conversionBuffer, error: &nsError) { packetCount, inputStatusPointer in
            defer { bufferProcessed = true } // This closure can be called multiple times, but it only offers a single buffer.
            inputStatusPointer.pointee = bufferProcessed ? .noDataNow : .haveData
            return bufferProcessed ? nil : buffer
        }
        
        guard status != .error else {
            throw Error.conversionFailed(nsError)
        }
        
        return conversionBuffer
    }
}
