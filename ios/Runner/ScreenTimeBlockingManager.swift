import Foundation
import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings

/// App blocking on iOS via Apple's official Screen Time API (iOS 16+).
///
/// Uses FamilyControls for authorization and app selection (FamilyActivityPicker)
/// and ManagedSettings to shield the selected apps. The selected apps are opaque
/// tokens - the app never learns which apps the user picked, which is exactly
/// how Apple wants third-party blockers to work.
@available(iOS 16.0, *)
final class ScreenTimeBlockingManager {

    static let shared = ScreenTimeBlockingManager()

    private let store = ManagedSettingsStore()
    private let selectionKey = "goalify_screen_time_selection"
    private let activeKey = "goalify_screen_time_blocking_active"

    private init() {}

    // MARK: - Authorization

    var isAuthorized: Bool {
        AuthorizationCenter.shared.authorizationStatus == .approved
    }

    var authorizationStatus: String {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved: return "approved"
        case .denied: return "denied"
        case .notDetermined: return "notDetermined"
        @unknown default: return "notDetermined"
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run { completion(true) }
            } catch {
                await MainActor.run { completion(false) }
            }
        }
    }

    // MARK: - Selection persistence

    private func loadSelection() -> FamilyActivitySelection {
        guard let data = UserDefaults.standard.data(forKey: selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return selection
    }

    private func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: selectionKey)
        }
        // If blocking is currently running, apply the new selection immediately
        if UserDefaults.standard.bool(forKey: activeKey) {
            applyShield(selection)
        }
    }

    var selectionCount: Int {
        let selection = loadSelection()
        return selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }

    // MARK: - Blocking

    /// Starts shielding the selected apps.
    /// Throws a descriptive error string via the completion when preconditions fail.
    func startBlocking() -> (success: Bool, errorCode: String?) {
        guard isAuthorized else {
            return (false, "SCREEN_TIME_NOT_AUTHORIZED")
        }
        let selection = loadSelection()
        let isEmpty = selection.applicationTokens.isEmpty
            && selection.categoryTokens.isEmpty
            && selection.webDomainTokens.isEmpty
        guard !isEmpty else {
            return (false, "NO_APPS_SELECTED")
        }
        applyShield(selection)
        UserDefaults.standard.set(true, forKey: activeKey)
        return (true, nil)
    }

    func stopBlocking() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        UserDefaults.standard.set(false, forKey: activeKey)
    }

    private func applyShield(_ selection: FamilyActivitySelection) {
        store.shield.applications =
            selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories =
            selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains =
            selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    // MARK: - App picker UI

    /// Presents Apple's FamilyActivityPicker so the user can choose which apps
    /// to block. Calls completion with the new selection count, or nil if cancelled.
    func presentAppPicker(
        from presenter: UIViewController,
        doneLabel: String,
        cancelLabel: String,
        completion: @escaping (Int?) -> Void
    ) {
        var hostingController: UIViewController?

        let pickerView = ScreenTimeAppPickerView(
            initialSelection: loadSelection(),
            doneLabel: doneLabel,
            cancelLabel: cancelLabel
        ) { [weak self] selection in
            hostingController?.dismiss(animated: true)
            guard let self, let selection else {
                completion(nil)
                return
            }
            self.saveSelection(selection)
            completion(self.selectionCount)
        }

        let controller = UIHostingController(rootView: pickerView)
        controller.modalPresentationStyle = .formSheet
        controller.isModalInPresentation = true
        hostingController = controller
        presenter.present(controller, animated: true)
    }
}

@available(iOS 16.0, *)
private struct ScreenTimeAppPickerView: View {
    @State private var selection: FamilyActivitySelection
    private let doneLabel: String
    private let cancelLabel: String
    private let onFinish: (FamilyActivitySelection?) -> Void

    init(
        initialSelection: FamilyActivitySelection,
        doneLabel: String,
        cancelLabel: String,
        onFinish: @escaping (FamilyActivitySelection?) -> Void
    ) {
        _selection = State(initialValue: initialSelection)
        self.doneLabel = doneLabel
        self.cancelLabel = cancelLabel
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(cancelLabel) { onFinish(nil) }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(doneLabel) { onFinish(selection) }
                            .fontWeight(.semibold)
                    }
                }
        }
    }
}
