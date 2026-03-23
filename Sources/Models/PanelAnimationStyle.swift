import Foundation

enum PanelAnimationStyle: String, CaseIterable, Codable, Identifiable {
    case breathGlow
    case pulse
    case particle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breathGlow: "呼吸光晕"
        case .pulse: "进度脉搏"
        case .particle: "粒子漂移"
        }
    }
}
