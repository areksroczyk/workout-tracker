import Foundation

enum DateFormatters {
    /// For API communication (ISO 8601 UTC)
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Parses API date strings, including timestamps without a timezone suffix.
    static func parseAPIDate(_ string: String) -> Date? {
        if let date = iso8601.date(from: string) {
            return date
        }

        let fractionalWithoutTimezone = ISO8601DateFormatter()
        fractionalWithoutTimezone.formatOptions = [.withFullDate, .withTime, .withFractionalSeconds]
        fractionalWithoutTimezone.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = fractionalWithoutTimezone.date(from: string) {
            return date
        }

        let posix = DateFormatter()
        posix.locale = Locale(identifier: "en_US_POSIX")
        posix.timeZone = TimeZone(secondsFromGMT: 0)
        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
        ] {
            posix.dateFormat = format
            if let date = posix.date(from: string) {
                return date
            }
        }

        return nil
    }

    /// Display date: "Jan 15, 2025"
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Display time: "10:30 AM"
    static let displayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Display date and time: "Jan 15, 2025 at 10:30 AM"
    static let displayDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Format a duration in seconds to "1h 15m"
    static func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Format elapsed time for the active session timer: "01:15:30"
    static func formatElapsed(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
