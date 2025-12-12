//
//  LaunchView.swift
//  VibeFocus
//
//  The main view displayed after the initial setup has been completed.
//  This view is shown on all subsequent launches after the first launch.
//

import SwiftUI

struct LaunchView: View {

    // MARK: - State Properties

    /// Comma-separated list of app names to keep visible (whitelist)
    @State private var whitelistInput: String = ""

    /// List of currently running applications, updated on view appear
    @State private var runningApps: [String] = []

    /// Status message to display after hide action
    @State private var statusMessage: String = ""

    // MARK: - Computed Properties

    /// Parses the comma-separated input into an array of trimmed app names
    private var whitelistedApps: [String] {
        whitelistInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Accessibility permissions notice
            accessibilityNotice

            Divider()

            // App title
            Text("VibeFocus")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Main content in horizontal split
            HStack(alignment: .top, spacing: 24) {
                // Left side: Whitelist input
                whitelistSection

                Divider()

                // Right side: Running apps list
                runningAppsSection
            }
            .frame(maxHeight: .infinity)

            // Status message
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            // Action button
            Button(action: startFocusMode) {
                Text("Start Focus Mode")
                    .font(.headline)
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(whitelistedApps.isEmpty)
        }
        .padding(30)
        .frame(minWidth: 600, minHeight: 450)
        .onAppear {
            refreshRunningApps()
        }
    }

    // MARK: - View Components

    /// Notice about Accessibility permissions requirement
    private var accessibilityNotice: some View {
        HStack {
            Image(systemName: "lock.shield")
                .foregroundColor(.orange)

            Text("Requires Accessibility permissions: System Settings > Privacy & Security > Accessibility")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Open Settings") {
                ApplicationManager.openAccessibilitySettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal)
    }

    /// Whitelist input section
    private var whitelistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apps to Keep Visible")
                .font(.headline)

            Text("Enter app names separated by commas:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Safari, Finder, Notes", text: $whitelistInput)
                .textFieldStyle(.roundedBorder)

            // Show parsed whitelist
            if !whitelistedApps.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Whitelist (\(whitelistedApps.count) apps):")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(whitelistedApps, id: \.self) { app in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(app)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(minWidth: 200)
    }

    /// Running applications list section
    private var runningAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Running Applications")
                    .font(.headline)

                Spacer()

                Button(action: refreshRunningApps) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh list")
            }

            Text("Click an app name to add it to the whitelist:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Scrollable list of running apps
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(runningApps, id: \.self) { appName in
                        runningAppRow(appName: appName)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
        }
        .frame(minWidth: 200)
    }

    /// Individual row for a running application
    private func runningAppRow(appName: String) -> some View {
        let isWhitelisted = whitelistedApps.map { $0.lowercased() }.contains(appName.lowercased())

        return Button(action: {
            addToWhitelist(appName: appName)
        }) {
            HStack {
                Image(systemName: isWhitelisted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isWhitelisted ? .green : .secondary)

                Text(appName)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isWhitelisted ? Color.green.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    /// Refreshes the list of running applications
    private func refreshRunningApps() {
        runningApps = ApplicationManager.getRunningApplications()
    }

    /// Adds an app name to the whitelist input
    private func addToWhitelist(appName: String) {
        // Check if already in whitelist (case-insensitive)
        let lowercasedWhitelist = whitelistedApps.map { $0.lowercased() }
        if lowercasedWhitelist.contains(appName.lowercased()) {
            // Remove from whitelist
            let filtered = whitelistedApps.filter { $0.lowercased() != appName.lowercased() }
            whitelistInput = filtered.joined(separator: ", ")
        } else {
            // Add to whitelist
            if whitelistInput.isEmpty {
                whitelistInput = appName
            } else {
                whitelistInput += ", \(appName)"
            }
        }
    }

    /// Executes the hide all except whitelist action
    private func startFocusMode() {
        guard !whitelistedApps.isEmpty else {
            statusMessage = "Please add at least one app to the whitelist."
            return
        }

        // Check permissions first
        guard ApplicationManager.checkAccessibilityPermissions() else {
            statusMessage = "Accessibility permissions required. Click 'Open Settings' above."
            ApplicationManager.promptForAccessibilityPermissions()
            return
        }

        // Hide all apps except whitelisted ones
        ApplicationManager.hideAllExcept(appNames: whitelistedApps)
        statusMessage = "Focus mode activated! Hidden all apps except: \(whitelistedApps.joined(separator: ", "))"

        // Refresh the running apps list after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshRunningApps()
        }
    }
}

#Preview {
    LaunchView()
}
