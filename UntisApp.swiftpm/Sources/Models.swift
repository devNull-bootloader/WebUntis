import Foundation

// MARK: - ShortData

struct ShortData {
    let id: Int
    let name: String
    let longname: String

    static func array(from value: Any?) -> [ShortData] {
        guard let arr = value as? [[String: Any]] else { return [] }
        return arr.compactMap { dict in
            guard
                let id = dict["id"] as? Int,
                let name = dict["name"] as? String,
                let longname = dict["longname"] as? String
            else { return nil }
            return ShortData(id: id, name: name, longname: longname)
        }
    }
}

// MARK: - Lesson

struct Lesson: Identifiable {
    let id: Int
    let date: Int
    let startTime: Int
    let endTime: Int
    let subjects: [ShortData]
    let teachers: [ShortData]
    let rooms: [ShortData]
    let classes: [ShortData]
    let code: LessonCode?
    let info: String?

    enum LessonCode: String {
        case cancelled
        case irregular
    }

    var isCancelled: Bool { code == .cancelled }
    var isIrregular: Bool { code == .irregular }

    var formattedStartTime: String { formatTime(startTime) }
    var formattedEndTime: String { formatTime(endTime) }

    var subjectName: String { subjects.first?.name ?? "—" }
    var subjectLongName: String { subjects.first?.longname ?? "" }
    var teacherNames: String { teachers.map(\.name).joined(separator: ", ") }
    var roomNames: String { rooms.map(\.name).joined(separator: ", ") }

    private func formatTime(_ time: Int) -> String {
        let h = time / 100
        let m = time % 100
        return String(format: "%02d:%02d", h, m)
    }

    init?(raw: [String: Any]) {
        guard
            let id = raw["id"] as? Int,
            let date = raw["date"] as? Int,
            let startTime = raw["startTime"] as? Int,
            let endTime = raw["endTime"] as? Int
        else { return nil }

        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.subjects = ShortData.array(from: raw["su"])
        self.teachers = ShortData.array(from: raw["te"])
        self.rooms = ShortData.array(from: raw["ro"])
        self.classes = ShortData.array(from: raw["kl"])
        self.code = (raw["code"] as? String).flatMap(LessonCode.init(rawValue:))
        self.info = raw["info"] as? String
    }
}

// MARK: - Errors

enum WebUntisError: LocalizedError {
    case loginFailed(String?)
    case notAuthenticated
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .loginFailed(let msg):
            return "Login failed. \(msg ?? "Please check your credentials.")"
        case .notAuthenticated:
            return "Not authenticated. Please log in first."
        case .invalidResponse:
            return "Server returned an unexpected response."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
