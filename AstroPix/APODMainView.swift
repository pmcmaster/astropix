//
//  ContentView.swift
//  AstroPix
//
//  Created by Peter McMaster on 02/08/2024.
//

import SwiftUI

struct APODMainView: View {
    
    @State private var date = Date.now
    
    @State private var image: UIImage?
    @State private var title: String?
    @State private var explanation: String?
    @State private var copyright: String?
    @State private var videoURL: URL?
    
    @State private var notice: String?
    
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
            date = imageDetails.date
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
            APODImageViewTab(date: $date, image: image, title: title, explanation: explanation, copyright: copyright, videoURL: videoURL, isLoading: isLoading)
            APODHelpViewTab()
        }
        .onChange(of: date) { newDate in
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
    }
}

#Preview {
    return APODMainView()
}

