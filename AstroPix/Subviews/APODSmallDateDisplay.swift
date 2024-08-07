//
//  APODSmallDateDisplay.swift
//  AstroPix
//
//  Created by Peter McMaster on 06/08/2024.
//

import SwiftUI

struct APODSmallDateDisplay: View {
    @Binding var date: Date
    let dateTapAction: () -> Void
    
    func incrementDate() {
        if let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date) {
            date = nextDate
        }
    }
    
    func decrementDate() {
        if let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: date) {
            date = prevDate
        }
    }
    
    var formattedCurrentImageDate: String {
        return date.asISO8601String()
    }
    
    var disableNextDayButton: Bool {
        return date.asISO8601String() == Date.now.asISO8601String()
    }
    
    var body: some View {
        HStack {
            Button(action: decrementDate) {
                Image(systemName: "arrow.backward")
            }
            Button(action: dateTapAction) {
                Text(formattedCurrentImageDate)
                    .fontWeight(.bold)
            }.padding(.horizontal)
            Button(action: incrementDate) {
                Image(systemName: "arrow.forward")
            }.disabled(disableNextDayButton)
        }
    }
}

#Preview("Different target & displayed dates") {
    @State var targetDate = Date.now
    return VStack {
        Spacer()
        APODSmallDateDisplay(date: $targetDate, dateTapAction: { debugPrint("Tapped") })
        Spacer()
        Spacer()
    }
}

#Preview("Displayed date is today") {
    @State var targetDate = Date.now
    return VStack {
        Spacer()
        APODSmallDateDisplay(date: $targetDate, dateTapAction: { debugPrint("Tapped") })
        Spacer()
        Spacer()
    }
}
