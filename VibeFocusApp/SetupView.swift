//
//  SetupView.swift
//  VibeFocus
//
//  The initial setup view displayed on the first launch of the application.
//  Guides users through initial configuration before transitioning to LaunchView.
//

import SwiftUI

struct SetupView: View {

    /// Binding to control the first launch state, allowing transition to LaunchView
    @Binding var isFirstLaunch: Bool

    /// Current step in the setup process
    @State private var currentStep: Int = 0

    /// Total number of setup steps
    private let totalSteps: Int = 3

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
                    setupStepTwo
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
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
    }

    private var setupStepTwo: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)

            Text("Step 2: Accessibility Permissions")
                .font(.title3)
                .fontWeight(.semibold)

            Text("VibeFocus requires Accessibility permissions to manage application windows. Please grant access in System Settings > Privacy & Security > Accessibility.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 350)

            Button("Open System Settings") {
                openAccessibilitySettings()
            }
            .buttonStyle(.bordered)
        }
    }

    private var setupStepThree: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Step 3: You're All Set!")
                .font(.title3)
                .fontWeight(.semibold)

            Text("VibeFocus is ready to help you focus. Click 'Get Started' to begin your first focus session.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 350)
        }
    }

    // MARK: - Actions

    /// Opens System Settings to the Accessibility preferences pane
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Completes the setup process and transitions to the main LaunchView
    private func completeSetup() {
        withAnimation {
            isFirstLaunch = false
        }
    }
}

#Preview {
    SetupView(isFirstLaunch: .constant(true))
}
