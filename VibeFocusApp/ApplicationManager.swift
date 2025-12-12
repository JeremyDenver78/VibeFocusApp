//
//  ApplicationManager.swift
//  VibeFocus
//
//  Provides functionality to manage running applications using the macOS Accessibility API.
//

import AppKit
import ApplicationServices

// MARK: - Accessibility Permissions Requirement
//
// IMPORTANT: This code requires Accessibility permissions to function properly.
//
// The user must grant Accessibility access to this application in:
//   System Settings > Privacy & Security > Accessibility
//
// Without these permissions, the hideAllExcept function will not be able to
// interact with other applications' windows.
//
// To check if permissions are granted programmatically, use:
//   AXIsProcessTrusted()
//
// To prompt the user for permissions, use:
//   AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary)
//

/// Manages running applications on macOS, providing utilities for window and app management.
struct ApplicationManager {

    // MARK: - Public Methods

    /// Returns a list of all currently running application names.
    ///
    /// This function queries the system for all running applications with a regular
    /// activation policy (i.e., apps that appear in the Dock and can be switched to).
    ///
    /// - Returns: An array of application names sorted alphabetically.
    ///
    /// - Note: This does not require Accessibility permissions as it uses NSWorkspace.
    ///
    /// - Example:
    ///   ```swift
    ///   let apps = ApplicationManager.getRunningApplications()
    ///   // Returns: ["Finder", "Safari", "Xcode", ...]
    ///   ```
    static func getRunningApplications() -> [String] {
        let runningApps = NSWorkspace.shared.runningApplications

        let appNames = runningApps.compactMap { app -> String? in
            // Only include regular applications (those that appear in the Dock)
            guard app.activationPolicy == .regular,
                  let name = app.localizedName else {
                return nil
            }
            return name
        }

        return appNames.sorted()
    }

    /// Hides all running applications except those specified in the provided array.
    ///
    /// This function uses the macOS Accessibility API to hide applications.
    /// It requires Accessibility permissions to be granted in System Settings.
    ///
    /// - Parameter appNames: An array of application names (as displayed in the menu bar)
    ///   that should NOT be hidden. All other visible applications will be hidden.
    ///
    /// - Note: The function will silently fail if Accessibility permissions are not granted.
    ///   Use `checkAccessibilityPermissions()` to verify permissions before calling this method.
    ///
    /// - Example:
    ///   ```swift
    ///   // Hide all apps except Finder and Safari
    ///   ApplicationManager.hideAllExcept(appNames: ["Finder", "Safari"])
    ///   ```
    static func hideAllExcept(appNames: [String]) {
        // Verify Accessibility permissions are granted
        guard AXIsProcessTrusted() else {
            print("⚠️ Accessibility permissions not granted. Cannot hide applications.")
            print("Please enable Accessibility access in: System Settings > Privacy & Security > Accessibility")
            promptForAccessibilityPermissions()
            return
        }

        // Convert app names to a Set for O(1) lookup
        let allowedApps = Set(appNames.map { $0.lowercased() })

        // Get all running applications
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            // Skip apps without a name or that aren't regular applications
            guard let appName = app.localizedName,
                  app.activationPolicy == .regular else {
                continue
            }

            // Skip apps that are in our allowed list
            if allowedApps.contains(appName.lowercased()) {
                continue
            }

            // Hide the application using NSRunningApplication
            // This is more reliable than using AXUIElement for hiding
            let success = app.hide()

            if success {
                print("✓ Hidden: \(appName)")
            } else {
                print("✗ Failed to hide: \(appName)")
            }
        }
    }

    // MARK: - Permission Helpers

    /// Checks if Accessibility permissions have been granted for this application.
    ///
    /// - Returns: `true` if Accessibility permissions are granted, `false` otherwise.
    static func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Prompts the user to grant Accessibility permissions if not already granted.
    ///
    /// This will display a system dialog asking the user to enable Accessibility
    /// access for this application. The dialog includes a button to open System Settings.
    ///
    /// - Returns: `true` if permissions are already granted, `false` if the prompt was shown.
    @discardableResult
    static func promptForAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Opens the Accessibility pane in System Settings.
    ///
    /// Use this to direct users to manually enable Accessibility permissions.
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Advanced Accessibility API Usage (for reference)

    /// Hides a specific application using the Accessibility API directly.
    ///
    /// This is an alternative implementation using AXUIElement for more granular control.
    /// Useful when you need to perform other accessibility operations beyond just hiding.
    ///
    /// - Parameter app: The NSRunningApplication to hide.
    /// - Returns: `true` if the operation was successful, `false` otherwise.
    static func hideAppUsingAccessibilityAPI(_ app: NSRunningApplication) -> Bool {
        // Create an AXUIElement for the application
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        // Set the hidden attribute to true
        let result = AXUIElementSetAttributeValue(
            axApp,
            kAXHiddenAttribute as CFString,
            true as CFBoolean
        )

        return result == .success
    }

    /// Gets all windows for a specific application using the Accessibility API.
    ///
    /// - Parameter app: The NSRunningApplication to get windows for.
    /// - Returns: An array of AXUIElement objects representing the app's windows, or nil if failed.
    static func getWindowsForApp(_ app: NSRunningApplication) -> [AXUIElement]? {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            axApp,
            kAXWindowsAttribute as CFString,
            &windowsRef
        )

        guard result == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return nil
        }

        return windows
    }
}
