import SwiftUI

struct DifferentiateKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var differentiate: Bool {
        get { self[DifferentiateKey.self] }
        set { self[DifferentiateKey.self] = newValue }
    }
}

extension View {
    func differentiate(_ enabled: Bool) -> some View {
        environment(\.differentiate, enabled)
    }
}
