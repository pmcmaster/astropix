//
//  APODHelpViewTab.swift
//  AstroPix
//
//  Created by Peter McMaster on 07/08/2024.
//

import SwiftUI

struct APODHelpViewTab: View {
    var body: some View {
        APODHelpView()
        .tabItem {
            Label(
                title: { Text("Help") },
                icon: { Image(systemName: "questionmark.circle")})
        }
    }
}

#Preview {
    TabView {
        APODHelpViewTab()
    }
}
