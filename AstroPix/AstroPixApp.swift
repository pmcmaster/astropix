//
//  AstroPixApp.swift
//  AstroPix
//
//  Created by Peter McMaster on 02/08/2024.
//

import SwiftUI

@main
struct AstroPixApp: App {
    var body: some Scene {
        WindowGroup {
            APODMainView()
                .onAppear {
                    debugPrint("Main View Appeared")
                }
        }
    }
}
