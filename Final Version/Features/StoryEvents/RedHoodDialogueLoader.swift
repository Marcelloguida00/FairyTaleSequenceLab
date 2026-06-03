import Foundation

struct DialogueLine: Codable, Sendable, Identifiable {
    let speaker: String
    let text: String

    var id: String { "\(speaker)-\(text.prefix(24))" }
}

struct RedHoodWaypointDialogue: Codable, Sendable {
    let waypoint: Int
    let eventId: Int?
    let introDialogue: [DialogueLine]?
    let rewardDialogue: [DialogueLine]?
    let rewardDialogue_success: [DialogueLine]?
    let rewardDialogue_retry: [DialogueLine]?
}

private struct RedHoodDialogueFile: Codable, Sendable {
    let waypoints: [RedHoodWaypointDialogue]
}

enum RedHoodDialogueLoader {
    private static let cachedEnglish: [RedHoodWaypointDialogue] = load(from: .main)

    static func entry(for waypointID: Int, from bundle: Bundle = .main) -> RedHoodWaypointDialogue? {
        let entries = load(from: bundle)
        let source = entries.isEmpty ? cachedEnglish : entries
        return source.first { $0.waypoint == waypointID }
    }

    static func introLines(waypoint waypointID: Int, from bundle: Bundle = .main) -> [DialogueLine]? {
        entry(for: waypointID, from: bundle)?.introDialogue.flatMap { $0.isEmpty ? nil : $0 }
    }

    static func introLines(eventId: Int, from bundle: Bundle = .main) -> [DialogueLine]? {
        introLines(waypoint: eventId, from: bundle)
    }

    static func rewardLines(
        eventId: Int,
        attemptCount: Int,
        from bundle: Bundle = .main
    ) -> [DialogueLine]? {
        guard let wp = entry(for: eventId, from: bundle) else { return nil }
        let lines: [DialogueLine]?
        if attemptCount == 0 {
            lines = wp.rewardDialogue_success ?? wp.rewardDialogue
        } else {
            lines = wp.rewardDialogue_retry ?? wp.rewardDialogue_success ?? wp.rewardDialogue
        }
        guard let lines, !lines.isEmpty else { return nil }
        return lines
    }

    static func finalLines(from bundle: Bundle = .main) -> [DialogueLine]? {
        entry(for: 9, from: bundle)?.rewardDialogue.flatMap { $0.isEmpty ? nil : $0 }
    }

    private static func load(from bundle: Bundle) -> [RedHoodWaypointDialogue] {
        guard let url = bundle.url(forResource: "redhood_dialogue", withExtension: "json")
                ?? bundle.url(
                    forResource: "redhood_dialogue",
                    withExtension: "json",
                    subdirectory: "Resources/Data"
                ),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(RedHoodDialogueFile.self, from: data) else {
            return []
        }
        return file.waypoints
    }
}

enum DialogueSpeakerRole: Equatable {
    case lumi
    case redRidingHood
    case other(String)

    init(speakerName: String) {
        let normalized = speakerName
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        if normalized.contains("lumi") {
            self = .lumi
        } else if normalized.contains("cappuccetto") || normalized.contains("red riding") {
            self = .redRidingHood
        } else {
            self = .other(speakerName)
        }
    }

    var displayName: String {
        switch self {
        case .lumi:
            return "Lumi"
        case .redRidingHood:
            return "Cappuccetto Rosso"
        case .other(let name):
            return name
        }
    }
}

enum DialoguePortraitExpression {
    case talk
    case listen
    case happy
    case sad
    case surprise

    static func lumiSpeaking(line: DialogueLine) -> DialoguePortraitExpression {
        let text = line.text.lowercased()
        if text.contains("guarda lass") || text.contains("perché piangi") {
            return .surprise
        }
        if text.contains("evviva") || text.contains("ce l'abbiamo fatta") || text.contains("fatto!") {
            return .happy
        }
        return .talk
    }

    static func redRidingHoodSpeaking(line: DialogueLine) -> DialoguePortraitExpression {
        let text = line.text.lowercased()
        if text.contains("trist") || text.contains("piangi") || text.contains("mescolato") {
            return .sad
        }
        if text.contains("evviva") || text.contains("grazie") || text.contains("felicit") || text.contains("fantastico") {
            return .happy
        }
        return .talk
    }
}

enum DialoguePortraitAssets {
    static func imageName(role: DialogueSpeakerRole, speaking: Bool, line: DialogueLine) -> String {
        switch role {
        case .lumi:
            if speaking {
                switch DialoguePortraitExpression.lumiSpeaking(line: line) {
                case .happy: return "Lumi_happy"
                case .surprise: return "Lumi_surprise"
                default: return "Lumi_talk"
                }
            }
            return "Lumi_listening_cover"
        case .redRidingHood:
            if speaking {
                switch DialoguePortraitExpression.redRidingHoodSpeaking(line: line) {
                case .sad: return "Cap_sad"
                case .happy: return "Cap_happy"
                default: return "Cap_talk"
                }
            }
            return "Cap_listening_cover"
        case .other:
            return speaking ? "Lumi_talk" : "Lumi_listening_cover"
        }
    }
}
