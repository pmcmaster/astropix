//
//  Networking.swift
//  AstroPix
//
//  Created by Peter McMaster on 02/08/2024.
//

import Foundation

let NASA_APOD_API_HOST = "api.nasa.gov"
let NASA_APOD_API_PATH = "/planetary/apod"
let EXPECTED_APOD_IMAGE_HOST = "apod.nasa.gov"

/// Things that can go wrong with networking. These are not (so far) explicitly handled.
enum APODNetworkError: Error {
    case badHTTPReturnCode
    case noHTTPResponse
    case imageNotOnExpectedHost // Only willing to load images from EXPECTED_APOD_IMAGE_HOST
    case networkAccessorCannotFetchLastGood
    case noAPIKey
}

struct APODAPIKeyStore {

    // Would ideally store the API key in CloudKit
    private static let APIURL = "https://fourteetoh.com/api_key_2024-08-02.txt"
    
    /// Save the API key after first retrieval
    private static var API_Key: String?
    
    /// API for accessing the key
    static func apiKey() async throws -> String? {
        if let cachedKey = Self.API_Key {
            debugPrint("Using cached API key")
            return cachedKey }
        
        if let scrambledAPIKey = try await fetchScrambledAPIKey() {
            let unscrambledKey = descrambleAPIKey(scrambledAPIKey)
            Self.API_Key = unscrambledKey
            return unscrambledKey
        }
        return nil
    }
    
    /// Descramble the API key from its form on the server to the key we'll actually use
    static func descrambleAPIKey(_ rawKey: String) -> String {
        let cleanedKey = rawKey.replacingOccurrences(of: "\n", with: "")
        let trimmedKey = String(cleanedKey.suffix(38))
        let finalKey = trimmedKey + "xx"
        debugPrint("Descrambled to API key: \(finalKey)")
        return finalKey
    }
    
    /// API key is stored very lightly 'scrambled' on the server
    private static func fetchScrambledAPIKey() async throws -> String? {
        let (data, response) = try await URLSession.shared.data(from: URL(string: APIURL)!)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("No HTTP response")
            throw APODNetworkError.noHTTPResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            debugPrint("Good response code \(httpResponse.statusCode) for API key fetch")
            if let rawKey = String(data: data, encoding: .utf8) {
                debugPrint("Fetched raw API key: \(rawKey)")
                return rawKey
            }
        default:
            debugPrint("HTTP error (status code \(httpResponse.statusCode)) for API key fetch")
            throw APODNetworkError.badHTTPReturnCode
        }
        return nil
    }
    
}

class APODNetworkAccessor: APODContentAccessProtocol {
    
    static let NASA_APOD_API_HOST = "api.nasa.gov"
    static let NASA_APOD_API_PATH = "/planetary/apod"
    static let EXPECTED_APOD_IMAGE_HOST = "apod.nasa.gov"
    
    /// Can't know from a network call alone what the last successfully-loaded image was. Only the cache can implement this
    func fetchLastGoodAPOD() async throws -> (APODResourceMetaInfo, Data) {
        throw APODNetworkError.networkAccessorCannotFetchLastGood
    }
    
    func fetchAPODImage(from imageURL: URL) async throws -> Data {
        debugPrint("Fetching image from \(imageURL)")
        let request = URLRequest(url: imageURL)
        let data = try await fetchResource(request)
        return data
    }
    
    /// Interaction with network accessor and API key provider. Extracted to this function to make testing easier
    func apiKey() async throws -> String {
        guard let apiKey = try await APODAPIKeyStore.apiKey() else { throw APODNetworkError.noAPIKey }
        return apiKey
    }
    
    /// Fetch the data for `date` (or 'latest', if date is not supplied)
    /// Does not attempt to parse that data
    /// Parameter passed to the call 'thumbs' is required to get thumbnail image info for video resources
    func fetchAPODRawMetadata(for date: Date? = nil) async throws -> Data {
        let apiKey = try await apiKey()
        var components = baseAPIURLComponents()
        var queryParams = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "thumbs", value: "true"),
        ]
        
        if let dateString = date?.asISO8601String() {
            queryParams.append(URLQueryItem(name: "date", value: dateString))
        }
        components.queryItems = queryParams
        let request = URLRequest(url: components.url!)
        debugPrint("Fetching metadata from \(request)")
        let jsonData = try await fetchResource(request)
        return jsonData
    }
    
    /// Protocol, host and port for calling the API
    private func baseAPIURLComponents() -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.NASA_APOD_API_HOST
        components.path = Self.NASA_APOD_API_PATH
        return components
    }
    
    /// Centralised function for actual network access, whether querying API, or downloading image
    /// Overridden in a sub-class of this class for testing purposes
    func fetchResource(_ urlRequest: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("No HTTP response")
            throw APODNetworkError.noHTTPResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            debugPrint("Good response code \(httpResponse.statusCode) for \(urlRequest)")
            return data
        default:
            debugPrint("HTTP error (status code \(httpResponse.statusCode)) for \(urlRequest)")
            throw APODNetworkError.badHTTPReturnCode
        }
    }
    
    func fetchAPODMetadata(for date: Date? = nil) async throws -> APODResourceMetaInfo {
        let jsonData = try await fetchAPODRawMetadata(for: date)
        let decodedData = try APODResourceDetail.decodedFrom(json: jsonData)
        return decodedData
    }
    
    func fetchAPOD(for date: Date? = nil) async throws -> (APODResourceMetaInfo, Data) {
        let imageMetaInfo = try await fetchAPODMetadata(for: date)
        let imageURL = imageMetaInfo.imageURL
        guard imageURL.host() == Self.EXPECTED_APOD_IMAGE_HOST else {
            throw APODNetworkError.imageNotOnExpectedHost
        }
        let imageData = try await fetchAPODImage(from: imageURL)
        return (imageMetaInfo, imageData)
    }

}
