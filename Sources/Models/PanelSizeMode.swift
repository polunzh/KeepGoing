import Foundation

enum PanelSizeMode: String, CaseIterable, Codable, Identifiable {
    case standard
    case compact

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: "标准"
        case .compact: "迷你"
        }
    }
}
