import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var currentPage = 0

    private let skyTop = Color(red: 0.05, green: 0.12, blue: 0.22)
    private let skyBottom = Color(red: 0.10, green: 0.32, blue: 0.52)

    private struct PageData {
        enum Visual {
            case logo
            case villainImage(String)
            case map
        }

        let visual: Visual
        let mascotFrames: [String]
        let titleKey: String
        let bodyKey: String
    }

    private let pages: [PageData] = [
        PageData(
            visual: .logo,
            mascotFrames: ["Mascot Waving", "Mascot Neutral", "Mascot Waving"],
            titleKey: "onboarding.page1.title",
            bodyKey: "onboarding.page1.body"
        ),
        PageData(
            visual: .villainImage("villain_action"),
            mascotFrames: ["Mascot Neutral", "Mascot Talking", "Mascot Neutral"],
            titleKey: "onboarding.page2.title",
            bodyKey: "onboarding.page2.body"
        ),
        PageData(
            visual: .villainImage("villain_rage"),
            mascotFrames: ["Mascot Talking", "Mascot Neutral", "Mascot Talking"],
            titleKey: "onboarding.page3.title",
            bodyKey: "onboarding.page3.body"
        ),
        PageData(
            visual: .map,
            mascotFrames: ["Mascot Cheer", "Mascot Waving", "Mascot Cheer"],
            titleKey: "onboarding.page4.title",
            bodyKey: "onboarding.page4.body"
        ),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                        pageView(page, geo: geo)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                topSkipButton(geo: geo)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Scene

    private func pageView(_ page: PageData, geo: GeometryProxy) -> some View {
        let isLandscape = geo.size.width > geo.size.height
        let mascotHeight = isLandscape
            ? min(geo.size.height * 0.62, 430)
            : min(geo.size.height * 0.42, 310)

        return ZStack {
            sceneBackground(page.visual, geo: geo)

            AnimatedMascotPortrait(
                imageNames: page.mascotFrames,
                imageHeight: mascotHeight
            )
            .padding(.leading, isLandscape ? 18 : -18)
            .padding(.bottom, max(geo.safeAreaInsets.bottom, 0))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .zIndex(2)

            dialoguePanel(page, geo: geo)
                .padding(.leading, dialogueLeading(for: geo))
                .padding(.trailing, isLandscape ? 28 : 20)
                .padding(.bottom, max(geo.safeAreaInsets.bottom + 16, 24))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .zIndex(3)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func sceneBackground(_ visual: PageData.Visual, geo: GeometryProxy) -> some View {
        ZStack {
            LinearGradient(
                colors: [skyTop, skyBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            backgroundVisual(visual, geo: geo)

            LinearGradient(
                colors: [.clear, .black.opacity(0.40)],
                startPoint: UnitPoint(x: 0.5, y: 0.60),
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func backgroundVisual(_ visual: PageData.Visual, geo: GeometryProxy) -> some View {
        switch visual {
        case .logo:
            fullBleedImage("mappa", geo: geo)
                .saturation(0.92)
                .brightness(-0.06)

        case .villainImage(let name):
            fullBleedImage(name, geo: geo)
                .saturation(1.05)
                .contrast(1.04)

        case .map:
            fullBleedImage("mappa", geo: geo)
                .saturation(1.02)
        }
    }

    private func fullBleedImage(_ name: String, geo: GeometryProxy) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
    }

    // MARK: - Dialogue

    private func dialogueLeading(for geo: GeometryProxy) -> CGFloat {
        if geo.size.width > geo.size.height {
            return min(max(geo.size.width * 0.24, 220), 370)
        }

        return 20
    }

    private func dialoguePanel(_ page: PageData, geo: GeometryProxy) -> some View {
        let isLandscape = geo.size.width > geo.size.height

        return VStack(alignment: .leading, spacing: 10) {
            Text(lm.t(page.titleKey))
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(lm.t(page.bodyKey))
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineSpacing(3)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                pageIndicators

                Spacer(minLength: 12)

                nextButton
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, isLandscape ? 28 : 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.55))
        )
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.white : Color.white.opacity(0.30))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            }
        }
        .accessibilityHidden(true)
    }

    private var nextButton: some View {
        Button {
            if currentPage < pages.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
            } else {
                onFinish()
            }
        } label: {
            HStack(spacing: 9) {
                Text(currentPage < pages.count - 1 ? lm.t("onboarding.next") : lm.t("onboarding.start"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "sparkles")
                    .font(.system(size: 15, weight: .black))
            }
            .font(.system(.body, design: .rounded))
            .fontWeight(.black)
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.35), radius: 5, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func topSkipButton(geo: GeometryProxy) -> some View {
        if currentPage < pages.count - 1 {
            Button {
                onFinish()
            } label: {
                Text(lm.t("onboarding.skip"))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.52))
                            .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1.5))
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, max(geo.safeAreaInsets.top + 14, 24))
            .padding(.trailing, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}

private struct AnimatedMascotPortrait: View {
    let imageNames: [String]
    let imageHeight: CGFloat
    var frameDuration: Duration = .milliseconds(420)

    @State private var frameIndex = 0

    var body: some View {
        Image(currentImageName)
            .resizable()
            .scaledToFit()
            .frame(height: imageHeight)
            .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 8)
            .accessibilityHidden(true)
            .task(id: imageNames) {
                frameIndex = 0
                guard imageNames.count > 1 else { return }

                while !Task.isCancelled {
                    try? await Task.sleep(for: frameDuration)
                    frameIndex = (frameIndex + 1) % imageNames.count
                }
            }
    }

    private var currentImageName: String {
        guard !imageNames.isEmpty else { return "Mascot Neutral" }
        return imageNames[frameIndex % imageNames.count]
    }
}


#Preview("Onboarding") {
    OnboardingView(onFinish: {})
        .environmentObject(LanguageManager())
}
