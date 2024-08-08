//
//  ContentView.swift
//  AstroPix
//
//  Created by Peter McMaster on 02/08/2024.
//

import SwiftUI

struct APODMainView: View {
    
    @State private var date = Date.now
    
    @State private var apodInfo: APODResourceMetaInfo?
    @State private var image: UIImage?
    
    @State private var showDatePicker = false
    @State private var isLoading = false
    @State private var isLoadingLatest = true
    
    private let contentAccessor = APODContentCache()
    
    private func update(with imageDetails: APODResourceMetaInfo, displaying imageData: Data) {
        apodInfo = imageDetails
        if let loadedImage = UIImage(data: imageData) {
            // Ideally would use Image instead of UIImage, but need a UIImage later to pass to PDF view to get full-screen photo view
            // It's easy to to UIImage -> Image and non-trivial to go Image -> UIImage, so easier to have UIImage passed around
            image = loadedImage
        }
        date = imageDetails.date
        isLoading = false
    }
    
    private func update(for newDate: Date? = nil) {
        if let date = newDate {
            debugPrint("Update triggered with \(date)")
        } else {
            debugPrint("Updating to latest available")
        }
        isLoading = true
        showDatePicker = false
        Task {
            if let (imageDetails, imageData) = try? await contentAccessor.fetchAPOD(for: newDate) {
                update(with: imageDetails, displaying: imageData)
            } else {
                // TODO: Notify user at this point of loading last good image
                if let (imageDetails, imageData) = try? await contentAccessor.fetchLastGoodAPOD() {
                    update(with: imageDetails, displaying: imageData)
                }
            }
        }
    }
    
    var body: some View {
        TabView {
            APODImageViewTab(date: $date, image: image, title: apodInfo?.title, explanation: apodInfo?.explanation, copyright: apodInfo?.copyright, videoURL: apodInfo?.videoURL, isLoading: isLoading)
            APODHelpViewTab()
        }
        .onChange(of: date) { newDate in
            debugPrint("New target date: \(newDate)")
            if isLoadingLatest {
                debugPrint("Skipping update - date changed due to initial load from latest")
                isLoadingLatest = false
            } else {
                update(for: newDate)
            }
        }
        .onAppear {
#if DEBUG
            contentAccessor.showCacheDirectoryContents()
#endif
            update()
        }
    }
}

#Preview {
    return APODMainView()
}

