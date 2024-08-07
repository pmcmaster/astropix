//
//  APODSmallDateDisplay.swift
//  AstroPix
//
//  Created by Peter McMaster on 06/08/2024.
//

import SwiftUI

struct APODSmallDateDisplay: View {
    @Binding var targetDate: Date
    let currentImageDate: Date?
    let dateTapAction: () -> Void
    
    func incrementDate() {
        if let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentImageDate ?? targetDate) {
            targetDate = nextDate
        }
    }
    
    func decrementDate() {
        if let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: currentImageDate ?? targetDate) {
            targetDate = prevDate
        }
    }
    
    var formattedCurrentImageDate: String {
        if let currentImageDate = currentImageDate {
            return currentImageDate.asISO8601String()
        }
        return "Select date"
    }
    
    var formattedTargetDate: String {
        return targetDate.asISO8601String()
    }
    
    var disableNextDayButton: Bool {
        return currentImageDate?.asISO8601String() == Date.now.asISO8601String()
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

#Preview {
    @State var targetDate = Date.now
    let anotherDate = Calendar.current.date(byAdding: .day, value: -3, to: targetDate)!
    return VStack {
        Spacer()
        APODSmallDateDisplay(targetDate: $targetDate, currentImageDate: anotherDate, dateTapAction: { debugPrint("Tapped") })
        Spacer()
        Spacer()
    }
}
