import Foundation
import Network

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.liftd.networkmonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let connected = path.status == .satisfied
                self?.isConnected = connected
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil,
                    userInfo: ["isConnected": connected]
                )
            }
        }
        monitor.start(queue: queue)
    }
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
