import Foundation
import UserNotifications

/// Manages iOS notifications for active timers.
///
/// Strategy:
///   - Requests UNUserNotificationCenter authorization on first use.
///   - On startTimer: posts an immediate "info" notification and schedules a
///     silent completion notification for when the timer expires.
///   - On pause/resume: cancels the scheduled completion and reschedules.
///   - On stop/finish: cancels all pending notifications.
///
/// Note: iOS does not allow updating an in-progress notification's text
/// dynamically (Live Activities require a Widget Extension added in Xcode –
/// see docs/ios_live_activity_setup.md). This fallback uses static
/// notifications showing the timer end time, which works on all iOS versions.
class TimerNotificationManager {

    static let shared = TimerNotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let timerInfoId  = "goalify.timer.info"
    private let timerDoneId  = "goalify.timer.done"

    // MARK: – Public API

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Show a persistent "timer running" banner and schedule a completion alert.
    func startTimer(
        timerId: String,
        timerType: String,
        title: String,
        currentPhase: String,
        currentRound: Int,
        totalRounds: Int,
        remainingSeconds: Int
    ) {
        cancelAll()

        let endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        let endTime = timeString(from: endDate)

        // --- Running notification (shown immediately) ---
        let infoContent = UNMutableNotificationContent()
        infoContent.title = buildTitle(title: title, phase: currentPhase,
                                       round: currentRound, total: totalRounds)
        infoContent.body  = "Endet um \(endTime) · \(formatDuration(remainingSeconds)) verbleibend"
        infoContent.sound = .none
        infoContent.categoryIdentifier = "TIMER_RUNNING"

        let infoReq = UNNotificationRequest(
            identifier: timerInfoId,
            content: infoContent,
            trigger: nil  // immediate
        )
        center.add(infoReq)

        // --- Completion notification (scheduled) ---
        scheduleCompletion(title: title, after: remainingSeconds)
    }

    /// Update the running notification after a phase change.
    func updatePhase(
        title: String,
        currentPhase: String,
        currentRound: Int,
        totalRounds: Int,
        remainingSeconds: Int
    ) {
        startTimer(
            timerId: timerInfoId,
            timerType: "",
            title: title,
            currentPhase: currentPhase,
            currentRound: currentRound,
            totalRounds: totalRounds,
            remainingSeconds: remainingSeconds
        )
    }

    /// Update the notification to show a paused state.
    func pauseTimer(title: String, currentPhase: String, remainingSeconds: Int) {
        // Cancel the scheduled completion (timer is paused, won't finish at that time)
        center.removePendingNotificationRequests(withIdentifiers: [timerDoneId])

        let infoContent = UNMutableNotificationContent()
        infoContent.title = title + (currentPhase.isEmpty ? "" : " · \(currentPhase)")
        infoContent.body  = "⏸  \(formatDuration(remainingSeconds)) · Pausiert"
        infoContent.sound = .none

        let req = UNNotificationRequest(
            identifier: timerInfoId,
            content: infoContent,
            trigger: nil
        )
        center.add(req)
    }

    /// Reschedule completion notification when resuming.
    func resumeTimer(
        title: String,
        currentPhase: String,
        currentRound: Int,
        totalRounds: Int,
        remainingSeconds: Int
    ) {
        startTimer(
            timerId: timerInfoId,
            timerType: "",
            title: title,
            currentPhase: currentPhase,
            currentRound: currentRound,
            totalRounds: totalRounds,
            remainingSeconds: remainingSeconds
        )
    }

    /// Remove all timer notifications immediately.
    func stopTimer() {
        cancelAll()
    }

    /// Remove running notification, show a brief completion alert.
    func finishTimer(title: String, message: String) {
        center.removeDeliveredNotifications(withIdentifiers: [timerInfoId])
        center.removePendingNotificationRequests(withIdentifiers: [timerDoneId])

        let content = UNMutableNotificationContent()
        content.title = "✓ \(title) abgeschlossen"
        content.body  = message
        content.sound = .default

        let req = UNNotificationRequest(
            identifier: timerDoneId,
            content: content,
            trigger: nil
        )
        center.add(req)
    }

    // MARK: – Private helpers

    private func cancelAll() {
        center.removeDeliveredNotifications(withIdentifiers: [timerInfoId, timerDoneId])
        center.removePendingNotificationRequests(withIdentifiers: [timerInfoId, timerDoneId])
    }

    private func scheduleCompletion(title: String, after seconds: Int) {
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "✓ \(title) abgeschlossen"
        content.body  = "Dein Timer ist abgelaufen."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )
        let req = UNNotificationRequest(
            identifier: timerDoneId,
            content: content,
            trigger: trigger
        )
        center.add(req)
    }

    private func buildTitle(title: String, phase: String, round: Int, total: Int) -> String {
        var t = title
        if !phase.isEmpty { t += " · \(phase)" }
        if total > 1 && round > 0 { t += " (\(round)/\(total))" }
        return t
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func timeString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}
