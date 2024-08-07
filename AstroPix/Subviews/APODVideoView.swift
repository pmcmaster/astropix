//
//  APODVideoView.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import SwiftUI
import WebKit

// Adapted from explanation at https://sarunw.com/posts/swiftui-webview/
struct APODWebViewForVideo: UIViewRepresentable {
    
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        DispatchQueue.main.async { webView.load(request) }
    }
}

struct APODShadowPlayButton: View {
    var body: some View {
        ZStack {
            Image(systemName: "circle.fill")
                .font(.system(size: 150))
                .blur(radius: /*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
                .foregroundColor(.black)
            Image(systemName: "play.fill")
                .font(.system(size: 100.0))
                .foregroundColor(.white)
        }.opacity(0.7)
    }
}

struct APODVideoView: View {
    let image: UIImage
    let videoURL: URL
    
    @State var showFullVideoView = false
    
    var body: some View {
        VStack {
            if showFullVideoView {
                APODWebViewForVideo(url: videoURL)
            } else {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea(edges: .horizontal)
                    APODShadowPlayButton()
                }.onTapGesture {
                    showFullVideoView = true
                }
            }
        }
    }
}

#Preview {
    let sampleImage = UIImage(named: "sample_image")!
    let sampleVideoURL = URL(string: "https://www.youtube.com/embed/1R5QqhPq1Ik?rel=0")!
    return APODVideoView(image: sampleImage, videoURL: sampleVideoURL)
}
