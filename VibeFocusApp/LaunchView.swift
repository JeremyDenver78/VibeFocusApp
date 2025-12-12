//
//  LaunchView.swift
//  VibeFocus
//
//  The main view displayed after the initial setup has been completed.
//  This is the clean, minimalist screen for daily use.
//

import SwiftUI

struct LaunchView: View {
    // We use a simple ObservedObject for permission checks
    // NOTE: This assumes ApplicationManager is refactored into an ObservableObject if you want real-time updates.
    // For simplicity, we'll use @State and check onAppear for this version.
    @State private var hasAccessibilityPermission: Bool = false

    // Define the Vibe Presets
    private let quickLaunchVibes: [(name: String, icon: String)] = [
        ("Word & Email", "doc.text.fill"),
        ("Code & Web", "chevron.left.forwardslash.chevron.right"),
        ("Design & Music", "paintpalette.fill"),
        ("Quick Task", "bolt.fill")
    ]

    var body: some View {
        ZStack {
            // 1. Aesthetics: Full black background
            Color.black.ignoresSafeArea()

            VStack(spacing: 50) {
                // 2. Central Prompt
                Text("What do you want to work on?")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 80)

                // 3. Vibe Preset Boxes
                HStack(spacing: 20) {
                    ForEach(quickLaunchVibes, id: \.name) { vibe in
                        VibeButton(vibe: vibe) {
                            startVibe(vibeName: vibe.name)
                        }
                    }
                }
                .frame(maxWidth: 800)
                .padding(.horizontal, 40)

                // 4. Dropdown Menu
                Menu("More Vibes...") {
                    Button("Deep Focus") { startVibe(vibeName: "Deep Focus") }
                    Button("Meeting Prep") { startVibe(vibeName: "Meeting Prep") }
                    Button("Admin Tasks") { startVibe(vibeName: "Admin Tasks") }
                }
                .menuStyle(.borderlessButton)
                .foregroundColor(.white)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )

                Spacer()

            }
            // 6. Accessibility Indicator (Bottom Right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AccessibilityIndicator(hasPermission: hasAccessibilityPermission)
                        .onTapGesture {
                            // Offer to open settings if permission is missing
                            if !hasAccessibilityPermission {
                                ApplicationManager.openAccessibilitySettings()
                            }
                        }
                }
                .padding(20)
            }
        }
        .onAppear {
            // Check permissions when the view appears
            hasAccessibilityPermission = ApplicationManager.checkAccessibilityPermissions()
        }
        // Set a default size for the window, as it's the main entry point
        .frame(minWidth: 800, minHeight: 600)
    }

    // MARK: - Actions

    private func startVibe(vibeName: String) {
        print("Starting Vibe: \(vibeName)")

        // Safety check: Prompt user if permissions are missing
        if !ApplicationManager.checkAccessibilityPermissions() {
            hasAccessibilityPermission = ApplicationManager.promptForAccessibilityPermissions()
            print("Action Failed: Accessibility permissions are required to start a Vibe.")
            return
        }

        // --- Placeholder for actual Vibe logic (App Hiding) ---
        // For demonstration, let's assume the 'Word & Email' vibe whitelists "Finder" and "Mail"
        if vibeName == "Word & Email" {
            ApplicationManager.hideAllExcept(appNames: ["Finder", "Mail", "Microsoft Word"])
        }

        // NOTE: You'll implement a full VibePreset model later.
    }
}

// MARK: - Component Views

/// Custom button style for the quick-launch boxes
struct VibeButton: View {
    let vibe: (name: String, icon: String)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Image(systemName: vibe.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)

                Text(vibe.name)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain) // Use plain style for custom background
    }
}

/// Subtle indicator for Accessibility Permission status
struct AccessibilityIndicator: View {
    let hasPermission: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "circle.fill")
                .foregroundColor(hasPermission ? .green : .red)
                .font(.system(size: 8))

            Text(hasPermission ? "Focus Ready" : "Setup Required")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    LaunchView()
}
