//
//  ContentAccessInterface.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import Foundation

/// 
///
protocol APODContentAccessProtocol {
    
    func fetchAPOD(for date: Date?) async throws -> (APODResourceMetaInfo, Data)
    
    func fetchAPODMetadata(for date: Date?) async throws -> (APODResourceMetaInfo)
    
}


