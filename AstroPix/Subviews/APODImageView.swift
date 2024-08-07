//
//  APODImageView.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import SwiftUI
import PDFKit

// PDF view to allow scrolling/zooming etc. from https://stackoverflow.com/a/67577296/16966757
struct PhotoDetailView: UIViewRepresentable {
    let image: UIImage
    
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = PDFDocument()
        guard let page = PDFPage(image: image) else { return view }
        view.document?.insert(page, at: 0)
        view.autoScales = true
        return view
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
    }
}

struct APODCloseButton: View {
    
    let action: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Button(action: action, label: {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                })
                .padding()
                Spacer()
            }
        }
    }
}

#Preview {
    return APODCloseButton { debugPrint("Close button tapped") }
}

struct APODImageView: View {
    let image: UIImage
    
    @State var showFullScreen = false
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .ignoresSafeArea(edges: .horizontal)
            .onTapGesture {
                showFullScreen.toggle()
            }
            .fullScreenCover(isPresented: $showFullScreen, content: {
                ZStack {
                    PhotoDetailView(image: image)
                    APODCloseButton() { showFullScreen = false }
                }
                .onTapGesture(count: 2, perform: {
                    showFullScreen = false
                })
            })
    }
}

#Preview {
    let sampleImage = UIImage(named: "sample_image")!
    return APODImageView(image: sampleImage)
}

