//
//  Parsing.swift
//  AstroPix
//
//  Created by Peter McMaster on 03/08/2024.
//

import Foundation

struct APODCodableHelpers {
    static let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    static let jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(APODCodableHelpers.dateFormatter)
        return decoder
    }()
    
    static let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(APODCodableHelpers.dateFormatter)
        return encoder
    }
}

enum APODJSONParseError: Error {
    case unparsableJSON
    case videoMediaTypeWithNoVideoURL
}

enum APODSupportedMediaType : String, Codable {
    case image = "image"
    case video = "video"
    // According to code in API, can also be 'other', but that's not supported by this app,
    // so will (and should) fail parsing on that
}

struct APODResourceMetaInfo {
    let title: String
    let explanation: String
    let date: Date
    let copyright: String?
    let imageURL: URL
    let videoURL: URL?
}

extension String {
    
    func cleanNewlines() -> String {
        return self.replacingOccurrences(of: "^[\n\\s]+", with: "", options: .regularExpression) // Leading newlines or whitespace - remove
            .replacingOccurrences(of: "[\n\\s]+$", with: "", options: .regularExpression) // Trailing newlines or whitespace - remove
            .replacingOccurrences(of: "\n", with: " ", options: .regularExpression) // Internal newlines - replace with single space
    }
    
    func cleanMultipleSpaces() -> String {
        return self.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
    }
    
    func biggestBlockSplitByTripleSpaces() -> String {
        let threeSpaces = "   "
        let blocks = self.split(separator: threeSpaces)
        return String(blocks.max(by: {$1.count > $0.count})!)
    }
    
    func cleaned() -> String {
        return self.biggestBlockSplitByTripleSpaces().cleanNewlines().cleanMultipleSpaces()
    }
}

struct APODResourceDetail: Codable {
    
    let title: String
    let explanation: String
    let date: Date
    let media_type: APODSupportedMediaType
    let copyright: String?
    let url: URL // Main resource URL for videos, small image resource for images
    let thumbnail_url: URL? // Present only for video resources. Relies on thumbs=true param being set on API query
    
    func stripNewlines(from string: String ) -> String {
        let stripLeading = string.replacingOccurrences(of: "^\n+", with: "", options: .regularExpression)
        let stripTrailing = stripLeading.replacingOccurrences(of: "\n+$", with: "", options: .regularExpression)
        let replaceInternal = stripTrailing.replacingOccurrences(of: "\n", with: " ", options: .regularExpression)
        return replaceInternal
    }
    
    static func decodedFrom(json: Data) throws -> APODResourceMetaInfo {
        guard let resourceInfo = try? APODCodableHelpers.jsonDecoder.decode(APODResourceDetail.self, from: json) else { throw APODJSONParseError.unparsableJSON }
        debugPrint("Parsed info. Title: \(resourceInfo.title) (Media type: \(resourceInfo.media_type))")
        switch resourceInfo.media_type {
        case .image:
            return APODResourceMetaInfo(title: resourceInfo.title.cleaned(), explanation: resourceInfo.explanation.cleaned(), date: resourceInfo.date, copyright: resourceInfo.copyright?.cleaned(), imageURL: resourceInfo.url, videoURL: nil)
        case .video:
            guard let thumbnailURL = resourceInfo.thumbnail_url else { throw APODJSONParseError.videoMediaTypeWithNoVideoURL }
            return APODResourceMetaInfo(title: resourceInfo.title.cleaned(), explanation: resourceInfo.explanation.cleaned(), date: resourceInfo.date, copyright: resourceInfo.copyright?.cleaned(), imageURL: thumbnailURL, videoURL: resourceInfo.url)
        }
    }
    
}
