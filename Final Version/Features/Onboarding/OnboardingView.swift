import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var currentPage = 0

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
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                            pageView(page, geo: geo)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    bottomBar
                        .padding(.horizontal, 44)
                        .padding(.bottom, max(36, geo.safeAreaInsets.bottom + 16))
                        .padding(.top, 8)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func pageView(_ page: PageData, geo: GeometryProxy) -> some View {
        VStack(spacing: 36) {
            Spacer()

            Text(lm.t(page.titleKey))
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            visualElement(page.visual, geo: geo)

            MascotGuideView(
                imageName: page.mascotFrames[0],
                animatedImageNames: page.mascotFrames,
                message: lm.t(page.bodyKey),
                imageHeight: min(geo.size.height * 0.20, 160),
                bubbleFont: .system(.title3, design: .rounded)
            )
            .padding(.horizontal, 36)

            Spacer()
            Spacer()
        }
    }

    @ViewBuilder
    private func visualElement(_ visual: PageData.Visual, geo: GeometryProxy) -> some View {
        let maxH = min(geo.size.height * 0.26, 200)
        switch visual {
        case .logo:
            Image("world_of_fable_menu")
                .resizable()
                .scaledToFit()
                .frame(height: maxH)
                .accessibilityHidden(true)

        case .villainImage(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: geo.size.width * 0.80, maxHeight: maxH * 1.4)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)

        case .map:
            Image("mappa")
                .resizable()
                .scaledToFill()
                .frame(width: min(geo.size.width * 0.55, 380), height: maxH)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .center) {
            Button(lm.t("onboarding.skip")) { onFinish() }
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(Color.appSecondaryText)
                .opacity(currentPage < pages.count - 1 ? 1 : 0)
                .disabled(currentPage == pages.count - 1)
                .frame(minWidth: 80, alignment: .leading)

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage
                              ? Color.appAccent
                              : Color.appBorder.opacity(0.5))
                        .frame(width: i == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7),
                                   value: currentPage)
                }
            }

            Spacer()

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage += 1 }
                } else {
                    onFinish()
                }
            } label: {
                HStack(spacing: 10) {
                    if currentPage == pages.count - 1 {
                        Image(systemName: "star.fill").font(.title3)
                    }
                    Text(currentPage < pages.count - 1
                         ? lm.t("onboarding.next")
                         : lm.t("onboarding.start"))
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                    if currentPage == pages.count - 1 {
                        Image(systemName: "star.fill").font(.title3)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 26)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.appAccent)
                        .shadow(color: .black.opacity(0.22), radius: 8, y: 4)
                )
            }
            .buttonStyle(.plain)
            .frame(minWidth: 80, alignment: .trailing)
        }
    }
}

#Preview("Onboarding") {
    OnboardingView(onFinish: {})
        .environmentObject(LanguageManager())
}
