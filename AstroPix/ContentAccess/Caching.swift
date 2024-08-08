//
//  Caching.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import Foundation

struct APODLastGoodLoadInfo: Codable {
    let date: Date
}

enum APODCacheError: Error {
    case noLastDataToLoad
}

class APODContentCache: APODContentAccessProtocol {
    
    static let networkAccessor = APODNetworkAccessor()
    static let cacheDirectoryName = "last_good_load_cache"
    static let lastAccessFilename = "last_loaded.json"
    
    // MARK: Public APIs
    
    func fetchAPOD(for date: Date? = nil) async throws -> (APODResourceMetaInfo, Data) {
        let imageMetadata = try await fetchAPODMetadata(for: date)
        let imageData = try await fetchAPODImage(for: imageMetadata.date, from: imageMetadata.imageURL)
        cleanupOnSuccessfulLoad(for: imageMetadata.date)
        return (imageMetadata, imageData)
    }
    
    func fetchAPODMetadata(for date: Date? = nil) async throws -> (APODResourceMetaInfo) {
        if let date = date {
            if let cachedJSONData = cachedData(for: cacheMetaInfoURL(for: date)) {
                if let loadedData = try? APODResourceDetail.decodedFrom(json: cachedJSONData) {
                    return loadedData
                } else {
                    debugPrint("Error loading cached metadata")
                }
            }
        }
        
        let jsonDataFromNetwork = try await Self.networkAccessor.fetchAPODRawMetadata(for: date)
        let imageMetadata = try APODResourceDetail.decodedFrom(json: jsonDataFromNetwork)
        if let validURL = cacheMetaInfoURL(for: imageMetadata.date) {
            debugPrint("Saving meta data to \(validURL)...")
            try? jsonDataFromNetwork.write(to: validURL, options: [.atomic])
        }
        return imageMetadata
    }
    
    func fetchAPODImage(for date: Date, from remoteURL: URL) async throws -> Data {
        let cacheFileURL = cacheImageURL(for: date)
        if let cachedImageData = cachedData(for: cacheFileURL) {
            return cachedImageData
        }
        
        let imageDataFromNetwork = try await Self.networkAccessor.fetchAPODImage(from: remoteURL)
        if let validURL = cacheFileURL {
            debugPrint("Saving image data to \(validURL)...")
            try? imageDataFromNetwork.write(to: validURL, options: [.atomic])
        }
        return imageDataFromNetwork
    }
    
    // MARK: "Last good load" file
    
    func fetchLastGoodAPOD() async throws -> (APODResourceMetaInfo, Data) {
        if let lastGoodDate = lastGoodLoadDate() {
            let (imageMetadata, imageData) = try await fetchAPOD(for: lastGoodDate)
            return (imageMetadata, imageData)
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
    
    private func cachedData(for cacheFileURL: URL?) -> Data? {
        if let validURL = cacheFileURL {
            debugPrint("Checking for \(validURL)")
            if let dataFromCache = try? Data(contentsOf: validURL) {
                debugPrint("...found cache.")
                return dataFromCache
            } else {
                debugPrint("...cache miss.")
            }
        }
        return nil
    }
    
    private func cacheFolderURL() -> URL? {
        let cacheFolderURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appending(path: APODContentCache.cacheDirectoryName, directoryHint: .isDirectory)
        if let cacheFolderURL = cacheFolderURL {
            try? FileManager.default.createDirectory(at: cacheFolderURL, withIntermediateDirectories: false)
        }
        return cacheFolderURL
    }
    
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
