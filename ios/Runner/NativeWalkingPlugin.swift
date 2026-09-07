import CoreMotion
import Flutter
import UIKit

/// Core Motion retains historical steps while the UI is suspended. GPS is
/// handled independently by geolocator, only during an opted-in active walk.
final class NativeWalkingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private let pedometer = CMPedometer()
    private var sink: FlutterEventSink?
    private var token: String?
    private var sessionStart: Date?
    private var periodStart: Date?
    private var updatesActive = false
    private let liveActivity = WalkingLiveActivity()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func didBecomeActive() {
        guard let activeToken = token else { return }
        // Permission sheets temporarily make the app inactive. Query again
        // after they close so ActivityKit can create the card in the foreground.
        snapshot { [weak self] value in
            guard let self = self, self.token == activeToken else { return }
            self.sink?(value)
        }
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = NativeWalkingPlugin()
        registrar.addMethodCallDelegate(plugin, channel: FlutterMethodChannel(
            name: "wingstar/walking", binaryMessenger: registrar.messenger()))
        registrar.addMethodCallDelegate(plugin, channel: FlutterMethodChannel(
            name: "wingstar/device-state", binaryMessenger: registrar.messenger()))
        FlutterEventChannel(name: "wingstar/walking/events",
                            binaryMessenger: registrar.messenger())
            .setStreamHandler(plugin)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "load", "save":
            handleStorage(call.method, args: args, result: result)
        case "start":
            guard CMPedometer.isStepCountingAvailable() else {
                result(failure("unavailable", "Step counting needs a supported physical iPhone."))
                return
            }
            let permission = CMPedometer.authorizationStatus()
            guard permission != .denied && permission != .restricted else {
                result(failure("permission_denied", "Motion & Fitness access is disabled."))
                return
            }
            guard permission == .authorized || args["requestPermission"] as? Bool == true else {
                result(failure("permission_required", "Restoring a walk never asks for permission."))
                return
            }
            guard let newToken = args["token"] as? String,
                  let milliseconds = args["fromMs"] as? NSNumber else {
                result(failure("invalid_start", "Missing walk identifier or start time."))
                return
            }
            let from = Date(timeIntervalSince1970: milliseconds.doubleValue / 1000)
            let now = Date()
            guard from <= now && now.timeIntervalSince(from) <= 7 * 24 * 60 * 60 else {
                result(failure("expired_walk", "The saved walk is outside the recovery window."))
                return
            }
            pedometer.stopUpdates()
            token = newToken
            sessionStart = from
            beginUpdates()
            snapshot(result)
        case "snapshot":
            guard args["token"] as? String == token, token != nil else {
                result(failure("cancelled", "This walk is no longer active."))
                return
            }
            snapshot(result)
        case "stop":
            // A delayed stop from an older Dart session must not stop a new one.
            if args["token"] as? String == token {
                liveActivity.end()
                token = nil
                sessionStart = nil
                periodStart = nil
                pedometer.stopUpdates()
                updatesActive = false
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func effectiveStart() -> Date? {
        guard let sessionStart = sessionStart else { return nil }
        // The existing app displays today's activity. Yesterday's outstanding
        // steps are never attributed to today's missions or ranking.
        return max(sessionStart, Calendar.current.startOfDay(for: Date()))
    }

    private func beginUpdates() {
        guard let from = effectiveStart(), let activeToken = token else { return }
        periodStart = from
        pedometer.stopUpdates()
        updatesActive = true
        pedometer.startUpdates(from: from) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self, self.token == activeToken,
                      self.periodStart == from else { return }
                // Rollover can happen with no foreground UI timer running.
                if self.effectiveStart() != from {
                    self.beginUpdates()
                    return
                }
                if let error = error {
                    self.pedometer.stopUpdates()
                    self.updatesActive = false
                    self.liveActivity.end()
                    self.sink?(self.motionFailure(error))
                } else if let data = data {
                    self.sink?(self.payload(data, token: activeToken, from: from))
                }
            }
        }
    }

    private func snapshot(_ result: @escaping FlutterResult) {
        guard let from = effectiveStart(), let activeToken = token else {
            result(failure("cancelled", "There is no active walk."))
            return
        }
        if periodStart != from || !updatesActive { beginUpdates() }
        // This query is also made after foregrounding and just before ending a
        // walk, so a suspended Flutter engine does not lose the historical delta.
        pedometer.queryPedometerData(from: from, to: Date()) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self, self.token == activeToken,
                      self.periodStart == from, self.effectiveStart() == from else {
                    result(FlutterError(code: "cancelled", message: "Walk ended.", details: nil))
                    return
                }
                if let error = error {
                    self.liveActivity.end()
                    result(self.motionFailure(error))
                } else if let data = data {
                    result(self.payload(data, token: activeToken, from: from))
                } else {
                    result(self.failure("unavailable", "No pedometer data returned."))
                }
            }
        }
    }

    private func payload(_ data: CMPedometerData, token: String, from: Date) -> [String: Any] {
        if let sessionStart = sessionStart {
            liveActivity.update(steps: data.numberOfSteps.intValue,
                                startedAt: sessionStart, periodStart: from)
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return ["token": token, "steps": data.numberOfSteps.intValue,
                "liveActivityStatus": liveActivity.status,
                "liveActivityError": liveActivity.errorCode ?? "",
                "day": formatter.string(from: from),
                "periodStartMs": Int64(from.timeIntervalSince1970 * 1000)]
    }

    private func motionFailure(_ error: Error) -> FlutterError {
        let permission = CMPedometer.authorizationStatus()
        return failure(permission == .denied || permission == .restricted
                       ? "permission_denied" : "unavailable", error.localizedDescription)
    }

    private func failure(_ code: String, _ message: String) -> FlutterError {
        FlutterError(code: code, message: message, details: nil)
    }

    private func handleStorage(_ method: String, args: [String: Any], result: FlutterResult) {
        do {
            let folder = try FileManager.default.url(for: .applicationSupportDirectory,
                in: .userDomainMask, appropriateFor: nil, create: true)
            var file = folder.appendingPathComponent("wingstar-device-state.json")
            if method == "load" {
                result(FileManager.default.fileExists(atPath: file.path)
                       ? try String(contentsOf: file, encoding: .utf8) : "")
            } else {
                guard let value = args["value"] as? String,
                      let bytes = value.data(using: .utf8), bytes.count <= 5_000_000 else {
                    result(failure("invalid_state", "Invalid device record."))
                    return
                }
                _ = try JSONSerialization.jsonObject(with: bytes)
                try bytes.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                var flags = URLResourceValues()
                flags.isExcludedFromBackup = true
                try file.setResourceValues(flags)
                result(nil)
            }
        } catch {
            result(failure("storage_error", "The device record could not be read or saved."))
        }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        pedometer.stopUpdates()
    }
}
