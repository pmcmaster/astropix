//
//  Formatting.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import Foundation

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
