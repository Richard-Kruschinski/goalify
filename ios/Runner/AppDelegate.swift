import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let timerChannelName = "com.goalify/timer_service"
    private var timerChannel: FlutterMethodChannel?

    // Stores last known timer state for resume queries
    private var lastTimerTitle = "Timer"
    private var lastTimerPhase = ""
    private var lastTimerRound = 0
    private var lastTimerTotalRounds = 0

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let controller = window?.rootViewController as? FlutterViewController {
            timerChannel = FlutterMethodChannel(
                name: timerChannelName,
                binaryMessenger: controller.binaryMessenger
            )
            timerChannel?.setMethodCallHandler(handleTimerCall)
        }

        // Become the notification center delegate so foreground notifications show
        UNUserNotificationCenter.current().delegate = self

        // Request notification authorization upfront (needed for timer notifications)
        TimerNotificationManager.shared.requestAuthorization { _ in }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: – Timer MethodChannel handler

    private func handleTimerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "startTimer":
            let title          = args["title"] as? String ?? "Timer"
            let timerType      = args["timerType"] as? String ?? "pomodoro"
            let phase          = args["currentPhase"] as? String ?? ""
            let round          = args["currentRound"] as? Int ?? 0
            let totalRounds    = args["totalRounds"] as? Int ?? 0
            let remaining      = args["remainingSeconds"] as? Int ?? 0
            let timerId        = args["timerId"] as? String ?? "timer"

            lastTimerTitle      = title
            lastTimerPhase      = phase
            lastTimerRound      = round
            lastTimerTotalRounds = totalRounds

            TimerNotificationManager.shared.startTimer(
                timerId: timerId,
                timerType: timerType,
                title: title,
                currentPhase: phase,
                currentRound: round,
                totalRounds: totalRounds,
                remainingSeconds: remaining
            )
            result(nil)

        case "pauseTimer":
            let remaining = args["remainingSeconds"] as? Int ?? 0
            TimerNotificationManager.shared.pauseTimer(
                title: lastTimerTitle,
                currentPhase: lastTimerPhase,
                remainingSeconds: remaining
            )
            result(nil)

        case "resumeTimer":
            let remaining = args["remainingSeconds"] as? Int ?? 0
            TimerNotificationManager.shared.resumeTimer(
                title: lastTimerTitle,
                currentPhase: lastTimerPhase,
                currentRound: lastTimerRound,
                totalRounds: lastTimerTotalRounds,
                remainingSeconds: remaining
            )
            result(nil)

        case "stopTimer":
            TimerNotificationManager.shared.stopTimer()
            result(nil)

        case "finishTimer":
            let message = args["message"] as? String ?? "Timer abgeschlossen"
            TimerNotificationManager.shared.finishTimer(
                title: lastTimerTitle,
                message: message
            )
            result(nil)

        case "updatePhase":
            let phase       = args["currentPhase"] as? String ?? lastTimerPhase
            let round       = args["currentRound"] as? Int ?? lastTimerRound
            let totalRounds = args["totalRounds"] as? Int ?? lastTimerTotalRounds
            let remaining   = args["remainingSeconds"] as? Int ?? 0

            lastTimerPhase      = phase
            lastTimerRound      = round
            lastTimerTotalRounds = totalRounds

            TimerNotificationManager.shared.updatePhase(
                title: lastTimerTitle,
                currentPhase: phase,
                currentRound: round,
                totalRounds: totalRounds,
                remainingSeconds: remaining
            )
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // Show notifications even when app is in foreground (iOS 10+)
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
