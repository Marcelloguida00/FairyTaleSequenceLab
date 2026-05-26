import Foundation

struct CardData: Identifiable, Codable, Sendable {
    let id: Int
    let imageName: String
    let description: String
    let correctPosition: Int
}

struct EventData: Codable, Sendable {
    let id: Int
    let bannerTitle: String
    let introImageName: String
    let introText: String
    let cards: [CardData]
    let correctOrder: [Int]
    let learningOutcome: String

    /// Random order for the source deck (card ids by position). Differs each call.
    func makeShuffledStart() -> [Int] {
        var order = cards.map(\.id)
        repeat { order.shuffle() } while order == correctOrder && order.count > 1
        return order
    }
    let rewardImageName: String
    let rewardText: String
    let isLastEvent: Bool
}

enum EventLoader {
    // Fallback English events (cached once, always available)
    static let allEnglish: [EventData] = load(from: .main)

    static func all(from bundle: Bundle) -> [EventData] {
        let result = load(from: bundle)
        return result.isEmpty ? allEnglish : result
    }

    static func event(id: Int, from bundle: Bundle) -> EventData? {
        all(from: bundle).first { $0.id == id }
    }

    static func maxEventId(from bundle: Bundle) -> Int {
        all(from: bundle).map(\.id).max() ?? 2
    }

    // Highest playable level id using main bundle (used where no LanguageManager is available).
    static var maxEventId: Int { allEnglish.map(\.id).max() ?? 2 }

    private static func load(from bundle: Bundle) -> [EventData] {
        guard let url = bundle.url(forResource: "events", withExtension: "json")
                ?? bundle.url(forResource: "events", withExtension: "json", subdirectory: "Resources/Data"),
              let data = try? Data(contentsOf: url),
              let events = try? JSONDecoder().decode([EventData].self, from: data) else {
            return []
        }
        return events.sorted { $0.id < $1.id }
    }
}
