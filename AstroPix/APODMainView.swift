//
//  ContentView.swift
//  AstroPix
//
//  Created by Peter McMaster on 02/08/2024.
//

import SwiftUI

struct APODMainView: View {
    
    @State private var targetDate = Date.now // This is the date for what we're going to try to show
    
    @State private var image: UIImage?
    @State private var title: String?
    @State private var displayDate: Date? // Date for what is currently showing (displayed on UI)
    @State private var explanation: String?
    @State private var copyright: String?
    @State private var videoURL: URL?
    
    @State private var showDatePicker = false
    @State private var isLoading = false
    
    @State private var isFirstLoad = true
    
    private let contentAccessor = APODContentCache()
    
    private func update(with imageDetails: APODResourceMetaInfo, displaying imageData: Data) {
        DispatchQueue.main.async {
            isLoading = false
            title = imageDetails.title
            if let loadedImage = UIImage(data: imageData) {
                // Ideally would use Image instead of UIImage, but need a UIImage later to pass to PDF view to get full-screen photo view
                // It's easy to to UIImage -> Image and non-trivial to go Image -> UIImage, so easier to have UIImage passed around
                image = loadedImage
            }
            displayDate = imageDetails.date
            explanation = imageDetails.explanation
            copyright = imageDetails.copyright
            videoURL = imageDetails.videoURL
        }
    }
    
    private func update(for newDate: Date) {
        debugPrint("Update triggered with \(newDate)")
        isLoading = true
        showDatePicker = false
        Task {
            if let (imageDetails, imageData) = try? await contentAccessor.fetchAPOD(for: newDate) {
                update(with: imageDetails, displaying: imageData)
            } else if let (imageDetails, imageData) = try? await contentAccessor.fetchLastGoodAPOD() {
                update(with: imageDetails, displaying: imageData)
            }
        }
    }
    
    var body: some View {
        TabView {
            Group {
                if isLoading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Loading info for \(targetDate.asISO8601String())...")
                            .padding()
                    }
                } else {
                    VStack {
                        if let image = image, let title = title, let explanation = explanation {
                            if let videoURL = videoURL {
                                APODVideoView(image: image, videoURL: videoURL)
                            } else {
                                APODImageView(image: image)
                            }
                            APODSmallDateDisplay(targetDate: $targetDate, currentImageDate: displayDate) {
                                showDatePicker = true
                            }
                            APODTextDetailsView(title: title, explanation: explanation, copyright: copyright)
                                .padding(.bottom)
                                .padding(.horizontal)
                            
                        } else {
                            if image == nil {
                                Text("No data… so far")
                                    .font(.title)
                                    .padding()
                            } else {
                                Text("Where to next?")
                                    .font(.title)
                                    .padding()
                            }
                            Text("Select a date to start your Astronomical Journey…")
                                .font(.caption)
                            APODDatePicker(date: $targetDate, datePickerStatus: $showDatePicker, selectedDate: displayDate ?? targetDate)
                                .padding()
                        }
                    }
                    .ignoresSafeArea(edges: .horizontal)
                    .sheet(isPresented: $showDatePicker) {
                        APODDatePicker(date: $targetDate, datePickerStatus: $showDatePicker, selectedDate: displayDate ?? targetDate)
                    }
                }
            }
            .tabItem {
                Label(
                    title: { Text("APOD") },
                    icon: { Image(systemName: "moon.fill") })
            }
            .onChange(of: targetDate) { newDate in
                debugPrint("New target date: \(newDate)")
                update(for: newDate)
            }
            .onAppear {
                if isFirstLoad {
#if DEBUG
                    contentAccessor.showCacheDirectoryContents()
#endif
                    update(for: Date.now)
                }
                isFirstLoad = false
            }
            Group {
                APODHelpView()
            }
            .tabItem {
                Label(
                    title: { Text("Help") },
                    icon: { Image(systemName: "questionmark.circle")})
            }
        }
    }
}

#Preview {
    return APODMainView()
}

