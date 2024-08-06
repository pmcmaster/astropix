//
//  Caching.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import Foundation

// Full-blown caching implementation is described at https://www.swiftbysundell.com/articles/caching-in-swift/
// Would be useful if app has more than one single image to display,
// but coding a basic cache from scratch for now, since only have one image at a time in the app

struct APODLastGoodLoadInfo: Codable {
    let date: Date
}

enum APODCacheError: Error {
    case noLastDataToLoad
}

class APODContentCache: APODContentAccessProtocol {
    
    static let networkAccessor = APODNetworkAccessor()
    static let lastAccessFilename = "last_loaded.json"
    
    // MARK: Public APIs
    
    func fetchAPOD(for date: Date) async throws -> (APODResourceMetaInfo, Data) {
        let jsonData = try await fetchAPODMetaData(for: date)
        let imageMetaData = try APODResourceDetail.decodedFrom(json: jsonData)
        let imageData = try await fetchAPODImage(for: date, from: imageMetaData.imageURL)
        cleanupOnSuccessfulLoad(for: date)
        return (imageMetaData, imageData)
    }
    
    func fetchAPODMetaData(for date: Date) async throws -> (Data) {
        let cacheFileURL = cacheMetaInfoURL(for: date)
        if let validURL = cacheFileURL {
            debugPrint("Checking for \(validURL)")
            if let jsonData = try? Data(contentsOf: validURL) {
                debugPrint("...found cached meta info.")
                return jsonData
            } else {
                debugPrint("...cache miss for meta info.")
            }
        }
        
        let jsonDataFromNetwork = try await Self.networkAccessor.fetchAPODMetaData(for: date)
        if let validURL = cacheFileURL {
            debugPrint("Saving meta data to \(validURL)...")
            try? jsonDataFromNetwork.write(to: validURL, options: [.atomic])
        }
        return jsonDataFromNetwork
    }
    
    func fetchAPODImage(for date: Date, from remoteURL: URL) async throws -> Data {
        let cacheFileURL = cacheImageURL(for: date)
        if let validURL = cacheFileURL {
            debugPrint("Checking for \(validURL)")
            if let imageData = try? Data(contentsOf: validURL) {
                debugPrint("...found cached image.")
                return imageData
            } else {
                debugPrint("...cache miss for image.")
            }
        }
        
        let imageDataFromNetwork = try await Self.networkAccessor.fetchAPODImage(from: remoteURL)
        if let validURL = cacheFileURL {
            debugPrint("Saving image data to \(validURL)...")
            try? imageDataFromNetwork.write(to: validURL, options: [.atomic])
        }
        return imageDataFromNetwork
    }
    
    private func cacheFolderURL() -> URL? {
        let cacheFolderURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return cacheFolderURL
    }
    
    // MARK: "Last good load" file
    
    func fetchLastGoodAPOD() async throws -> (APODResourceMetaInfo, Data) {
        if let lastGoodDate = lastGoodLoadDate() {
            let (imageMetaData, imageData) = try await fetchAPOD(for: lastGoodDate)
            return (imageMetaData, imageData)
        }
        throw APODCacheError.noLastDataToLoad
    }
    
    private func cleanupOnSuccessfulLoad(for date: Date) {
        if let previousGoodLoadDate = lastGoodLoadDate() {
            guard previousGoodLoadDate != date else { return }
            do {
                try FileManager.default.removeItem(at: cacheImageURL(for: previousGoodLoadDate)!)
                try FileManager.default.removeItem(at: cacheMetaInfoURL(for: previousGoodLoadDate)!)
            } catch {
                debugPrint("Error while clearing up cache from prior load")
            }
        }
        self.updateLatestAvailable(to: date)
    }
    
    func lastGoodLoadDate() -> Date? {
        if let lastLoadInfoFilename = cacheURL(for: APODContentCache.lastAccessFilename) {
            if let lastGoodLoadData = try? Data(contentsOf: lastLoadInfoFilename) {
                if let parsedData = try? APODCodableHelpers.jsonDecoder.decode(APODLastGoodLoadInfo.self, from: lastGoodLoadData) {
                    return parsedData.date
                }
            }
        }
        return nil
    }
    
    private func updateLatestAvailable(to date: Date) {
        if let lastLoadInfoFilename = cacheURL(for: APODContentCache.lastAccessFilename) {
            let info = APODLastGoodLoadInfo(date: date)
            if let result = try? APODCodableHelpers.jsonEncoder().encode(info) {
                do {
                    try result.write(to: lastLoadInfoFilename)
                    debugPrint("Wrote last good load info (\(date)) to file")
                } catch {
                    debugPrint("Couldn't write info to last good load file")
                }
            }
        }
    }
    
    // MARK: Local URLs for cached files
    
    private func cacheURL(for filename: String) -> URL? {
        if let cacheFolderURL = cacheFolderURL() {
            let fileURL = cacheFolderURL.appending(path: filename)
            return fileURL
        }
        return nil
        
    }
    
    private func cacheImageURL(for date: Date) -> URL? {
        // Thought about trying to save with same filetype as the remote image, but not sure it will always have one
        let filename = APODFormattingHelpers.iso8601DateFormatter.string(from: date) + ".data"
        return cacheURL(for: filename)
    }
    
    private func cacheMetaInfoURL(for date: Date) -> URL? {
        let filename = APODFormattingHelpers.iso8601DateFormatter.string(from: date) + ".json"
        return cacheURL(for: filename)
    }
    
    
#if DEBUG
    func showCacheDirectoryContents() {
        if let cacheDir = cacheFolderURL() {
            if let dirContents = try? FileManager.default.contentsOfDirectory(atPath: cacheDir.path()) {
                debugPrint("Cache directory contains:")
                for eachFile in dirContents {
                    debugPrint("   \(eachFile)")
                }
            } else {
                debugPrint("Could not list cache directory")
            }
        }
    }
    
#endif
    
}
