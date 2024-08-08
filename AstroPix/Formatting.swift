//
//  Formatting.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import Foundation

/// Date formatter is used throughout the app.
/// Should technically use locale-specific formating for displayed dates, but banking on 'scientifically-minded' astronomy lovers not minding ISO-8601
/// Supporting reference: https://xkcd.com/1179/
class APODFormattingHelpers {
    static let iso8601DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
}

extension Date {
    
    func asISO8601String() -> String {
        return APODFormattingHelpers.iso8601DateFormatter.string(from: self)
    }
    
    static func fromISO8601String(_ dateString: String) -> Date? {
        return APODFormattingHelpers.iso8601DateFormatter.date(from: dateString)
    }
}
