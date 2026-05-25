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
    let shuffledStart: [Int]
    let learningOutcome: String
    let rewardImageName: String
    let rewardText: String
    let isLastEvent: Bool
}

enum EventLoader {
    static let all: [EventData] = {
        guard let url = Bundle.main.url(forResource: "events", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let events = try? JSONDecoder().decode([EventData].self, from: data) else {
            return []
        }
        return events.sorted { $0.id < $1.id }
    }()

    static func event(id: Int) -> EventData? {
        all.first { $0.id == id }
    }

    // Highest playable level id. Falls back to 2 when events.json is not in the bundle.
    static var maxEventId: Int {
        all.map(\.id).max() ?? 2
    }
}
