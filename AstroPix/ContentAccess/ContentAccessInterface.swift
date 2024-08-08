//
//  ContentAccessInterface.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import Foundation

///  Protocol intented to be common for 'access to APOD', whether that's via direct network calls or cache.
protocol APODContentAccessProtocol {
    
    /// Fetch APOD info and image for a given `date`
    ///
    /// Can throw in the case of (e.g.) network errors, or API failure
    ///
    /// - Parameters:
    ///     - date: Date to query APOD API for. If nil, fetch 'latest' info.
    ///
    /// - Returns: A tuple of `APODResourceMetaInfo`, which contains data associated with the image and `Data` which is the image data itself
    func fetchAPOD(for date: Date?) async throws -> (APODResourceMetaInfo, Data)
    
    /// Fetch APOD info for `date`
    ///
    /// Can throw in the case of (e.g.) network errors, or API failure
    ///
    /// - Parameters:
    ///     - date: Date to query APOD API for. If nil, fetch 'latest' info.
    ///
    /// - Returns: A `APODResourceMetaInfo`, which contains data associated with the image, including the URL of the image
    func fetchAPODMetadata(for date: Date?) async throws -> (APODResourceMetaInfo)
    
    /// Fetch the most recently available APOD info and image
    ///
    /// Can throw in the case of (e.g.) network errors, API failure or if this behaviour is not implementable by conforming instance
    ///
    /// - Returns: A tuple of `APODResourceMetaInfo`, which contains data associated with the image and `Data` which is the image data itself
    func fetchLastGoodAPOD() async throws -> (APODResourceMetaInfo, Data)
    
}


