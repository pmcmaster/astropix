//
//  APODHelpView.swift
//  AstroPix
//
//  Created by Peter McMaster on 06/08/2024.
//

import SwiftUI

struct APODHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Spacer()
                Text("AstroPix")
                    .font(.title)
                    .padding(.bottom)
                Text("This **AstroPix** app helps you to view the NASA Astronomy Photo of the Day (often referred to as APOD).")
                    .padding(.bottom)
                Text("The [APOD web site](https://apod.nasa.gov/apod/astropix.html) has been showcasing impressive astronomy- or meterology-related images since June 1995.")
                    .padding(.bottom)
                Text("A new photo (sometimes a video) is available *almost* every day, at around midnight US (Eastern) time.")
                    .padding(.bottom)
                Text("**AstroPix** allows you to view these images for previous dates of your choosing (and hopefully allows me to get a job building apps).")
                    .padding(.bottom)
                Text("Disclaimers").font(.headline)
                    .padding(.bottom)
                Text("NB: This app is not affiliated with or in any way endorsed by APOD or NASA.")
                    .font(.caption)
                    .padding(.bottom)
                Text("Images videos and text shown in the app remain the property of their respective rights holders. Images produced by NASA and other US government agencies are in the public domain, but APOD often features images which are often made by other organisations or individials, so this does not apply to all images in APOD. Lack of copyright info displayed with the images does not imply rights to free-use of the images.")
                    .font(.caption)
                Spacer()
            }.padding()
        }.padding()
    }
}

#Preview {
    APODHelpView()
}
