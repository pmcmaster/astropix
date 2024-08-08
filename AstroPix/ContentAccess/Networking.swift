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

enum APODNetworkError: Error {
    case badHTTPReturnCode
    case noHTTPResponse
    case imageNotOnExpectedHost
    case noAPIKey
}

class APODAPIKeyStore {

    // Would ideally store the API key in CloudKit
    static let APIURL = "https://fourteetoh.com/api_key_2024-08-02.txt"
    
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
    
    private static func descrambleAPIKey(_ rawKey: String) -> String {
        let cleanedKey = rawKey.replacingOccurrences(of: "\n", with: "")
        let trimmedKey = String(cleanedKey.suffix(38))
        let finalKey = trimmedKey + "xx"
        debugPrint("Descrambled to API key: \(finalKey)")
        return finalKey
    }
    
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
    
    private static var API_Key: String?
}

class APODNetworkAccessor: APODContentAccessProtocol {
    
    private func fetchResource(_ urlRequest: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("No HTTP response")
            throw APODNetworkError.noHTTPResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            debugPrint("Good response code \(httpResponse.statusCode) for \(urlRequest.url!)")
            return data
        default:
            debugPrint("HTTP error (status code \(httpResponse.statusCode)) for \(urlRequest.url!)")
            throw APODNetworkError.badHTTPReturnCode
        }
    }
    
    func fetchAPODImage(from imageURL: URL) async throws -> Data {
        debugPrint("Fetching image from \(imageURL)")
        let request = URLRequest(url: imageURL)
        let data = try await fetchResource(request)
        return data
    }
    
    private func baseAPIURLComponents() -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = NASA_APOD_API_HOST
        components.path = NASA_APOD_API_PATH
        return components
    }
    
    func fetchAPODRawMetadata(for date: Date? = nil) async throws -> Data {
        guard let apiKey = try await APODAPIKeyStore.apiKey() else { throw APODNetworkError.noAPIKey }
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
    
    func fetchAPODMetadata(for date: Date? = nil) async throws -> APODResourceMetaInfo {
        let jsonData = try await fetchAPODRawMetadata(for: date)
        let decodedData = try APODResourceDetail.decodedFrom(json: jsonData)
        return decodedData
    }
    
    func fetchAPOD(for date: Date? = nil) async throws -> (APODResourceMetaInfo, Data) {
        let imageMetaInfo = try await fetchAPODMetadata(for: date)
        let imageURL = imageMetaInfo.imageURL
        guard imageURL.host() == EXPECTED_APOD_IMAGE_HOST else {
            throw APODNetworkError.imageNotOnExpectedHost
        }
        let imageData = try await fetchAPODImage(from: imageURL)
        return (imageMetaInfo, imageData)
    }

}
