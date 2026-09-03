//
//  ImageFileManage.swift
//  Cue
//
//  Created by Krishna Venkatramani on 04/09/2026.
//

import Foundation
import AVKit

class ImageFileManager {
    
    enum FileManagerError: Error {
        case imageDataNotFound
        case imageWriteFailed
        case imageReadFailed
        case imageLoadFailed
        case imageRemovalFailed
    }
    
    /// Resolved on every access rather than cached: the app's data container path
    /// changes between installs, so an absolute URL is only valid for the current launch.
    static var directory: URL {
        let fileDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageDirectory = fileDirectory.appending(component: "images", directoryHint: .isDirectory)
        
        if !FileManager.default.fileExists(atPath: imageDirectory.path(percentEncoded: false)) {
            do {
                try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("(ERROR) \(Self.self).\(#function): ", error)
            }
        }
        
        return imageDirectory
    }
    
    /// Resolves a persisted file name against the current container.
    static func url(for fileName: String) -> URL {
        directory.appending(component: fileName)
    }
    
    /// Returns the file name to persist — never store the absolute URL.
    @discardableResult
    public func addImage(image: UIImage) async throws -> String {
        let fileName = UUID().uuidString + ".img"
        guard let imageData = image.jpegData(compressionQuality: 1) else { throw FileManagerError.imageDataNotFound }
        
        do {
            try imageData.write(to: Self.url(for: fileName))
            return fileName
        } catch {
            print("(ERROR) while try to add the image: \(error)")
            throw FileManagerError.imageWriteFailed
        }
    }
    
    public static func retrieveImage(for url: URL) throws -> UIImage {
        
        do {
            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else {
                throw FileManagerError.imageLoadFailed
            }
            return image
        } catch {
            print("(ERROR) \(Self.self).\(#function): ", error)
            throw FileManagerError.imageReadFailed
        }
    }
    
    public static func retrieveImage(named fileName: String) throws -> UIImage {
        try retrieveImage(for: url(for: fileName))
    }
    
    @discardableResult
    public func removeImage(for url: URL) async throws -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("(ERROR) \(Self.self).\(#function): ", error)
            throw FileManagerError.imageRemovalFailed
        }
    }
    
    @discardableResult
    public func removeImage(named fileName: String) async throws -> Bool {
        try await removeImage(for: Self.url(for: fileName))
    }
}
