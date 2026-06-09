import Foundation

/// Toggle in-progress features without removing their implementation.
enum AppFeatureFlags {
    /// About → Collaborators section (audio and other external contributors).
    static let showsCollaboratorsInAbout = true

    /// Settings → Sound → Orchestral sequencing SFX mode.
    static let showsOrchestralSequencingSFX = true

    /// First-launch onboarding flow and Settings → «Show onboarding again».
    static let showsOnboarding = true

    /// Cinematic villain intro (world map + clouds). When false, uses the paginated `OnboardingView`.
    static let usesVillainOnboardingCinematic = true
}
