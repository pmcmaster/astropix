//
//  APODTextDetailsView.swift
//  AstroPix
//
//  Created by Peter McMaster on 05/08/2024.
//

import SwiftUI

struct APODTextDetailsView: View {
    let title: String
    let explanation: String
    let copyright: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title)
                    .padding(.bottom)
                Group {
                    if let copyright = copyright {
                        Text("© \(copyright)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    Text(explanation)
                        .font(.callout)
                }.padding(.horizontal)
            }
        }
    }
}

#Preview("Description with copyright info") {
    let title = "A Picture Of Some Stars With A Long Title"
    let sampleDescription = "This is a photo of some awesome astronomical event. This one has the optional copyright info present. There is probably a fair amount of black in the picture, some white dots, and something unusual about it which may only be apparent when you read the description. If this is your first one, you might be unimpressed, but as you view more and more of these, you may learn to further appreciate the dedication, patience, technique and science that goes into making these remarkable and varied images."
    let copyright = "Dr Star Photographer; his esteemed collaborators, and other important contributors"
    return APODTextDetailsView(title: title, explanation: sampleDescription, copyright: copyright).padding()
        
}

#Preview("Description (no copyright info)") {
    let title = "A Picture Of Some Stars With A Long Title"
    let sampleDescription = "This is a photo of some awesome astronomical event. This one does not have any copyright info. There is probably a fair amount of black in the picture, some white dots, and something unusual about it which may only be apparent when you read the description. If this is your first one, you might be unimpressed, but as you view more and more of these, you may learn to further appreciate the dedication, patience, technique and science that goes into making these remarkable and varied images."
    return APODTextDetailsView(title: title, explanation: sampleDescription, copyright: nil).padding()
}
