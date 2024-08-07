//
//  APODDatePicker.swift
//  AstroPix
//
//  Created by Peter McMaster on 06/08/2024.
//

import SwiftUI

struct APODDatePicker: View {
    @Binding var date: Date
    @Binding var datePickerStatus: Bool
    @State var selectedDate: Date
    
    let startDate = APODFormattingHelpers.iso8601DateFormatter.date(from: "1995-06-16")!
    let endDate = Date.now // TODO: Only if after 12:00 or so Eastern time
    
    var formattedDisplayDate: String {
        APODFormattingHelpers.iso8601DateFormatter.string(from: selectedDate)
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    $date.wrappedValue = selectedDate
                    $datePickerStatus.wrappedValue = false
                }) {
                    Text("Fetch \(formattedDisplayDate)")
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
            }
            DatePicker("Select a date", selection: $selectedDate, in: startDate...endDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

#Preview("Date picker") {
    @State var date = Date.now
    @State var datePickerShown = true
    let anotherDate = Calendar.current.date(byAdding: .day, value: -3, to: date)!
    return APODDatePicker(date: $date, datePickerStatus: $datePickerShown, selectedDate: anotherDate)
}

#Preview("Date picker in sheet") {
    @State var date = Date.now
    @State var datePickerShown = true
    let anotherDate = Calendar.current.date(byAdding: .day, value: -3, to: date)!
    let randomStack = VStack {
        Text("Random text")
    }.sheet(isPresented: $datePickerShown, content: {
        APODDatePicker(date: $date, datePickerStatus: $datePickerShown, selectedDate: anotherDate)
    })
    return randomStack
}
