//
//  UpdaterManager.swift
//  AppleAppsControl
//
//  Wraps Sparkle's SPUStandardUpdaterController so the menu bar "Check for
//  Updates" downloads, installs, and relaunches in place instead of dropping a
//  DMG in Downloads. Uses ObservableObject (not @Observable) for the Combine
//  bridge from Sparkle's KVO-backed canCheckForUpdates.
//

import AppKit
import Combine
import Foundation
import Sparkle

@MainActor
final class UpdaterManager: NSObject, ObservableObject {
    static let shared = UpdaterManager()

    private let controller: SPUStandardUpdaterController

    @Published var canCheckForUpdates = false

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    private override init() {
        // startingUpdater: false — we call start() explicitly once the app has
        // finished launching so timing is under our control.
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()

        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    /// Begin the automatic update schedule. Called from applicationDidFinishLaunching.
    func start() {
        #if DEBUG
        // Never auto-update a debug build with a release artifact.
        return
        #else
        controller.startUpdater()
        #endif
    }

    /// Manually trigger an update check. The app runs as a menu-bar accessory,
    /// so switch to .regular first or Sparkle's window can't come forward.
    /// The AppDelegate's windowWillClose handler reverts to .accessory after.
    func checkForUpdates() {
        #if DEBUG
        return
        #else
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
        #endif
    }
}
