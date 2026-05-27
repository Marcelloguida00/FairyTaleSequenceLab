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
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                        pageView(page, geo: geo)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack {
                    Spacer()
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
        let mascotHeight = min(geo.size.height * 0.32, 260)
        let mascotWidth = min(geo.size.width * 0.24, 280)
        let bubbleWidth = min(geo.size.width * 0.66, 980)
        let bubbleHeight = min(max(geo.size.height * 0.12, 116), 160)

        return ZStack {
            backgroundElement(page.visual, geo: geo)

            Color.black.opacity(0.18)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.58),
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.64)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Text(lm.t(page.titleKey))
                .font(.app(.largeTitle))
                .fontWeight(.black)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 40)
                .padding(.top, max(46, geo.safeAreaInsets.top + 24))
                .shadow(color: .black.opacity(0.60), radius: 8, y: 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            OnboardingDialogueView(
                imageName: page.mascotFrames[0],
                animatedImageNames: page.mascotFrames,
                message: lm.t(page.bodyKey),
                mascotWidth: mascotWidth,
                mascotHeight: mascotHeight,
                bubbleWidth: bubbleWidth,
                bubbleHeight: bubbleHeight,
                bubbleFont: .system(.title3, design: .rounded)
            )
            .padding(.leading, max(18, geo.safeAreaInsets.leading + 18))
            .padding(.trailing, max(24, geo.safeAreaInsets.trailing + 24))
            .padding(.bottom, max(122, geo.safeAreaInsets.bottom + 102))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    @ViewBuilder
    private func backgroundElement(_ visual: PageData.Visual, geo: GeometryProxy) -> some View {
        switch visual {
        case .logo:
            Image("world_of_fable_menu")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)

        case .villainImage(let name):
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)

        case .map:
            Image("mappa")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .center) {
            Button(lm.t("onboarding.skip")) { onFinish() }
                .font(.app(.body))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.34)))
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
                        .font(.app(.body))
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

private struct OnboardingDialogueView: View {
    let imageName: String
    let animatedImageNames: [String]
    let message: String
    let mascotWidth: CGFloat
    let mascotHeight: CGFloat
    let bubbleWidth: CGFloat
    let bubbleHeight: CGFloat
    let bubbleFont: Font

    @State private var frameIndex = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            Image(currentImageName)
                .resizable()
                .scaledToFit()
                .frame(width: mascotWidth, height: mascotHeight, alignment: .bottomLeading)
                .shadow(color: .black.opacity(0.24), radius: 7, y: 4)
                .accessibilityHidden(true)

            Text(message)
                .font(bubbleFont)
                .fontWeight(.semibold)
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(width: bubbleWidth, height: bubbleHeight, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.appSpeechBubble)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.appBorder, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
                )

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .task(id: animatedImageNames) {
            guard !animatedImageNames.isEmpty else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(420))
                frameIndex = (frameIndex + 1) % animatedImageNames.count
            }
        }
    }

    private var currentImageName: String {
        guard !animatedImageNames.isEmpty else { return imageName }
        return animatedImageNames[frameIndex % animatedImageNames.count]
    }
}

#Preview("Onboarding") {
    OnboardingView(onFinish: {})
        .environmentObject(LanguageManager())
}
