//
//  SwiftUIView.swift
//  AstroPix
//
//  Created by Peter McMaster on 07/08/2024.
//

import SwiftUI

struct APODProgressIndicator: View {
    
    let date: Date
    
    var body: some View {
        VStack {
            ProgressView("Loading for \(date.asISO8601String())...")
                .controlSize(.large)
                .padding()
                .padding(.horizontal)
        }
        .background(.regularMaterial.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 25.0))
    }
}

struct APODImageViewTab: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @Binding var date: Date
    
    let image: UIImage?
    let title: String?
    let explanation: String?
    let copyright: String?
    let videoURL: URL?
    
    let isLoading: Bool
    
    @State private var showDatePicker = false
    
    var body: some View {
        GeometryReader { geo in
            if let title = title, let explanation = explanation, let image = image {
                if geo.size.height < geo.size.width { // Very very very basic approach to nicer display on iPad
                    HStack {
                        APODMediaView(image: image, videoURL: videoURL)
                        VStack {
                            Spacer()
                            APODSmallDateDisplay(date: $date, dateTapAction: {
                                showDatePicker = true
                            })
                            .sheet(isPresented: $showDatePicker) {
                                APODDatePicker(date: $date, showDatePicker: $showDatePicker, selectedDate: $date.wrappedValue)
                            } // TODO: Move this to the SmallDateDisplay
                            APODTextDetailsView(title: title, explanation: explanation, copyright: copyright)
                                .padding(.bottom)
                                .padding(.horizontal)
                        }
                    }
                } else {
                    VStack {
                        APODMediaView(image: image, videoURL: videoURL)
                        APODSmallDateDisplay(date: $date, dateTapAction: {
                            showDatePicker = true
                        })
                        .sheet(isPresented: $showDatePicker) {
                            APODDatePicker(date: $date, showDatePicker: $showDatePicker, selectedDate: $date.wrappedValue)
                        }
                        APODTextDetailsView(title: title, explanation: explanation, copyright: copyright)
                            .padding(.bottom)
                            .padding(.horizontal)
                    }
                }
            } else if !isLoading { // No title or explanation
                VStack {
                    Text("Where to next?")
                        .font(.title)
                        .padding()
                    Spacer()
                }
                    .onAppear() { showDatePicker = true }
                    .sheet(isPresented: $showDatePicker) {
                        APODDatePicker(date: $date, showDatePicker: $showDatePicker, selectedDate: $date.wrappedValue)
                    }
            }
        }.frame(maxWidth: .infinity)
        .opacity(isLoading ? 0.2 : 1.0)
        .overlay(
            Group {
                if isLoading {
                    APODProgressIndicator(date: date)
                }
            }
        )
        .ignoresSafeArea(edges: .horizontal)
        .tabItem {
            Label(
                title: { Text("APOD") },
                icon: { Image(systemName: "moon.fill") })
        }
    }
}

#Preview("Image and details") {
    @State var targetDate = Date.now
    let sampleImage = UIImage(named: "sample_image")!
    return TabView {
        APODImageViewTab(date: $targetDate, image: sampleImage, title: "Astronomy Photo", explanation: "This is a photo for preview purposes", copyright: "Photographer", videoURL: nil, isLoading: false)
    }
}

#Preview("Image (no details)") {
    @State var targetDate = Date.now
    let sampleImage = UIImage(named: "sample_image")!
    return TabView {
        APODImageViewTab(date: $targetDate, image: sampleImage, title: nil, explanation: nil, copyright: nil, videoURL: nil, isLoading: false)
    }
}

#Preview("Video and details") {
    @State var targetDate = Date.now
    let sampleImage = UIImage(named: "sample_image")!
    let sampleVideoURL = URL(string: "https://www.youtube.com/embed/1R5QqhPq1Ik?rel=0")!
    return TabView {
        APODImageViewTab(date: $targetDate, image: sampleImage, title: "Astronomy Photo", explanation: "This is a photo for preview purposes", copyright: "Photographer", videoURL: sampleVideoURL, isLoading: false)
    }
}

#Preview("Loading from blank") {
    @State var targetDate = Date.now
    let sampleImage = UIImage(named: "sample_image")!
    return TabView {
        APODImageViewTab(date: $targetDate, image: sampleImage, title: nil, explanation: nil, copyright: nil, videoURL: nil, isLoading: true)
    }
}

#Preview("Loading from existing image and details") {
    @State var targetDate = Date.now
    let sampleImage = UIImage(named: "sample_image")!
    return TabView {
        APODImageViewTab(date: $targetDate, image: sampleImage, title: "Astronomy Photo", explanation: "This is a photo for preview purposes", copyright: "Photographer", videoURL: nil, isLoading: true)
    }
}
#Preview("Details only, no image") {
    @State var targetDate = Date.now
    return TabView {
        APODImageViewTab(date: $targetDate, image: nil, title: "Astronomy Photo", explanation: "This is a photo for preview purposes", copyright: "Photographer", videoURL: nil, isLoading: false)
    }
}

#Preview("No details, no image") {
    @State var targetDate = Date.now
    return TabView {
        APODImageViewTab(date: $targetDate, image: nil, title: nil, explanation: nil, copyright: nil, videoURL: nil, isLoading: false)
    }
}
