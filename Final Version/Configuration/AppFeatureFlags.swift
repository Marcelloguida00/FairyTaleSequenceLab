import Foundation

/// Toggle in-progress features without removing their implementation.
enum AppFeatureFlags {
    /// About → Collaborators section (audio and other external contributors).
    static let showsCollaboratorsInAbout = false

    /// Settings → Sound → Orchestral sequencing SFX mode.
    static let showsOrchestralSequencingSFX = false

    /// First-launch onboarding flow and Settings → «Show onboarding again».
    static let showsOnboarding = false
}
