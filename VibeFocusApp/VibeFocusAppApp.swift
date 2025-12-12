//
//  VibeFocusAppApp.swift
//  VibeFocusApp
//
//  Created by Jeremy E on 12/11/25.
//

import SwiftUI

@main
struct VibeFocusAppApp: App {

    // MARK: - First Launch Detection

    /// Key used to store first launch status in UserDefaults
    private static let hasLaunchedBeforeKey = "hasLaunchedBefore"

    /// Indicates whether this is the first time the app has been launched
    /// Returns `true` if this is the first launch, `false` otherwise
    @State private var isFirstLaunch: Bool = {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey)

        if !hasLaunchedBefore {
            // First launch - set the flag for future launches
            UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
            return true
        }

        return false
    }()

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            // Conditional view routing based on first launch status
            if isFirstLaunch {
                SetupView(isFirstLaunch: $isFirstLaunch)
            } else {
                LaunchView()
            }
        }
    }
}
