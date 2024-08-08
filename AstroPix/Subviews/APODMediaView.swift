//
//  APODMediaView.swift
//  AstroPix
//
//  Created by Peter McMaster on 07/08/2024.
//

import SwiftUI

struct APODMediaView: View {
    let image: UIImage
    let videoURL: URL?
    
    var body: some View {
        if let videoURL = videoURL {
            APODVideoView(image: image, videoURL: videoURL)
        } else {
            APODImageView(image: image)
        }
    }
}

#Preview("Image") {
    let sampleImage = UIImage(named: "sample_image")!
    return APODMediaView(image: sampleImage, videoURL: nil)
}

#Preview("Video") {
    let sampleImage = UIImage(named: "sample_image")!
    let sampleVideoURL = URL(string: "https://www.youtube.com/embed/1R5QqhPq1Ik?rel=0")!
    return APODMediaView(image: sampleImage, videoURL: sampleVideoURL)
}
