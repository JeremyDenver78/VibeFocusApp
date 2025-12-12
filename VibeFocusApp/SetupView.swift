//
//  SetupView.swift
//  VibeFocus
//
//  The initial setup view displayed on the first launch of the application.
//  Now includes aggressive, live checking for Accessibility Permissions.
//

import SwiftUI
import AppKit

struct SetupView: View {

    /// Binding to control the first launch state, allowing transition to LaunchView
    @Binding var isFirstLaunch: Bool

    /// Current step in the setup process
    @State private var currentStep: Int = 0

    /// Total number of setup steps (Added Vibe Presets as Step 3 for structure)
    private let totalSteps: Int = 3

    // MARK: - Live Permission Status
    @State private var hasAccessibilityPermission: Bool = false
    @State private var timer: Timer? = nil

    var body: some View {
        VStack(spacing: 30) {
            // Header
            Text("Welcome to VibeFocus")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Let's get you set up")
                .font(.title2)
                .foregroundColor(.secondary)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case 0:
                    setupStepOne
                case 1:
                    setupStepTwo // The live permission check step
                case 2:
                    setupStepThree
                default:
                    EmptyView()
                }
            }
            .transition(.opacity)

            Spacer()

            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }

            // Navigation buttons
            HStack(spacing: 20) {
                if currentStep > 0 {
                    Button("Back") {
                        stopLiveCheck()
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button("Next") {
                        if currentStep == 1 && !hasAccessibilityPermission {
                            // Block progression if on Step 2 and permission is missing
                            ApplicationManager.promptForAccessibilityPermissions()
                            return
                        }
                        stopLiveCheck()
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    // Disable Next if on the permission step and permission is NOT granted
                    .disabled(currentStep == 1 && !hasAccessibilityPermission)

                } else {
                    Button("Get Started") {
                        completeSetup()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: 400)
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 450)
        // Start and Stop the live check based on view lifecycle
        .onAppear {
            if currentStep == 1 { startLiveCheck() }
        }
        .onDisappear {
            stopLiveCheck()
        }
        // Re-check permissions every time the application comes to the front
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if currentStep == 1 { checkPermissionStatus() }
        }
    }

    // MARK: - Live Check Logic
    private func startLiveCheck() {
        checkPermissionStatus()
        // Start a timer to poll for permission status every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            checkPermissionStatus()
        }
    }

    private func stopLiveCheck() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPermissionStatus() {
        self.hasAccessibilityPermission = ApplicationManager.checkAccessibilityPermissions()
    }

    // MARK: - Setup Steps

    private var setupStepOne: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)

            Text("Step 1: Introduction")
                .font(.title3)
                .fontWeight(.semibold)

            Text("VibeFocus helps you stay productive by managing your application windows and minimizing distractions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 350)
        }
        .onAppear {
            stopLiveCheck() // Ensure timer is off
            checkPermissionStatus()
        }
    }

    private var setupStepTwo: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(hasAccessibilityPermission ? .green : .red)

            Text("Step 2: Accessibility Permissions")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(hasAccessibilityPermission ? .primary : .red)

            Text(hasAccessibilityPermission ?
                 "Permission Granted! The system recognizes VibeFocus." :
                 "Permission Missing. Click 'Open Settings' and enable VibeFocus in the Accessibility list.")
                .multilineTextAlignment(.center)
                .foregroundColor(hasAccessibilityPermission ? .green : .secondary)
                .frame(maxWidth: 350)

            if !hasAccessibilityPermission {
                Button("Open System Settings") {
                    ApplicationManager.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)
            } else {
                Text("You can now click 'Next' to continue setup.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            startLiveCheck() // Start timer when this step is visible
        }
    }

    private var setupStepThree: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Step 3: Setup Complete!")
                .font(.title3)
                .fontWeight(.semibold)

            Text("VibeFocus is ready to help you focus. Click 'Get Started' to begin your first clean focus session.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 350)
        }
        .onAppear {
            stopLiveCheck() // Timer no longer needed
            checkPermissionStatus()
        }
    }

    // MARK: - Actions

    /// Completes the setup process and transitions to the main LaunchView
    private func completeSetup() {
        // Set the UserDefaults flag to stop showing the setup view
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

        withAnimation {
            isFirstLaunch = false
        }
    }
}

#Preview {
    SetupView(isFirstLaunch: .constant(true))
}
