//
//  Final_VersionApp.swift
//  Final Version
//
//  Created by Marcello Guida on 22/05/26.
//

import SwiftUI

@main
struct Final_VersionApp: App {
    @StateObject private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(languageManager)
        }
    }
}
