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

struct APODContentCache: APODContentAccessProtocol {
    
    static let networkAccessor = APODNetworkAccessor()
    static let cacheDirectoryName = "last_good_load_cache"
    static let lastAccessFilename = "last_loaded.json"
    
    // MARK: Public APIs
    
    /// Fetch APOD info and image for a given `date`, checking in cache first, then (if required) making a network call
    ///
    /// Can throw in the case of (e.g.) network errors, or API failure. Cache retrieval problems themselves should not throw, and should fall-through to network access
    ///
    /// - Parameters:
    ///     - date: Date to query APOD API for. If nil, fetch 'latest' info.
    ///
    /// - Returns: A tuple of `APODResourceMetaInfo`, which contains data associated with the image and `Data` which is the image data itself
    func fetchAPOD(for date: Date? = nil) async throws -> (APODResourceMetaInfo, Data) {
        let imageMetadata = try await fetchAPODMetadata(for: date)
        let imageData = try await fetchAPODImage(for: imageMetadata.date, from: imageMetadata.imageURL)
        cleanupOnSuccessfulLoad(for: imageMetadata.date)
        return (imageMetadata, imageData)
    }
    
    /// Fetch APOD info for `date`, checking in cache first, then (if required) making a network call
    ///
    /// Can throw in the case of (e.g.) network errors, or API failure. Cache retrieval problems themselves should not throw, and should fall-through to network access
    ///
    /// - Parameters:
    ///     - date: Date to query APOD API for. If nil, fetch 'latest' info.
    ///
    /// - Returns: A `APODResourceMetaInfo`, which contains data associated with the image, including the URL of the image
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
    
    /// Fetch the image from the given `remoteURL`, after first checking if cached data is available.
    /// `date` is used to save to the correctly named cache file, and for the initial cache lookup
    private func fetchAPODImage(for date: Date, from remoteURL: URL) async throws -> Data {
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
    
    /// Fetch the most recently available APOD info and image, checking in cache. Cannot fall through to network as 'what was the last thing that worked' is undefinfined for network access if we don't have anything availble in the cache
    ///
    /// Can throw in the case of (e.g.) network errors, API failure or if this behaviour is not implementable by conforming instance
    ///
    /// - Returns: A tuple of `APODResourceMetaInfo`, which contains data associated with the image and `Data` which is the image data itself
    func fetchLastGoodAPOD() async throws -> (APODResourceMetaInfo, Data) {
        if let lastGoodDate = lastGoodLoadDate() {
            let (imageMetadata, imageData) = try await fetchAPOD(for: lastGoodDate)
            return (imageMetadata, imageData)
        }
        throw APODCacheError.noLastDataToLoad
    }
    
    /// Clean up the prior saved image info and image, then update the 'what is the last good info' file to point to the new one, referencing `date`
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
    
    /// What is the date for which we have 'last good load' cached data?
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
    
    /// Update the small JSON file which holds a reference to which date was the last good load
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
    
    /// Load cached data from the given URL
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
    
    /// Folder for caching data. Created (as sub-folder of default .cachesDirectory for the application) on first access, if required.
    private func cacheFolderURL() -> URL? {
        let cacheFolderURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appending(path: APODContentCache.cacheDirectoryName, directoryHint: .isDirectory)
        if let cacheFolderURL = cacheFolderURL {
            try? FileManager.default.createDirectory(at: cacheFolderURL, withIntermediateDirectories: false)
        }
        return cacheFolderURL
    }
    
    /// URL for a file named `filename` in the cache directory
    private func cacheURL(for filename: String) -> URL? {
        if let cacheFolderURL = cacheFolderURL() {
            let fileURL = cacheFolderURL.appending(path: filename)
            return fileURL
        }
        return nil
    }
    
    /// Cache URL for the image resource, for a given `date`
    /// Thought about trying to save with same filetype as the remote image (.jpg, .png etc.), but not sure it will always have one.
    /// Instead save as .data, and handle any errors converting that to a UIImage elsewhere
    private func cacheImageURL(for date: Date) -> URL? {
        // Thought about trying to save with same filetype as the remote image, but not sure it will always have one
        let filename = date.asISO8601String() + ".data"
        return cacheURL(for: filename)
    }
    
    /// Cache URL for the meta info for a given `date`
    private func cacheMetaInfoURL(for date: Date) -> URL? {
        let filename = date.asISO8601String() + ".json"
        return cacheURL(for: filename)
    }
    
    
#if DEBUG
    /// Prints out the current contents of the cache folder. Lightweight check to verify cleanup is behaving as expected.
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
