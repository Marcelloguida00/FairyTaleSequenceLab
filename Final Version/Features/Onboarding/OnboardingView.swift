import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var currentPage = 0

    // Sfondo sempre scuro come la mappa notturna
    private let skyTop    = Color(red: 0.05, green: 0.12, blue: 0.22)
    private let skyBottom = Color(red: 0.10, green: 0.32, blue: 0.52)

    private struct PageData {
        enum Visual {
            case logo                          // world_of_fable_menu
            case map                           // immagine mappa reale
            case symbol(String, Color)
        }
        let visual: Visual
        let mascotFrames: [String]
        let titleKey: String
        let bodyKey: String
    }

    private let pages: [PageData] = [
        PageData(visual: .logo,
                 mascotFrames: ["Mascot Waving", "Mascot Neutral", "Mascot Waving"],
                 titleKey: "onboarding.page1.title",
                 bodyKey:  "onboarding.page1.body"),
        PageData(visual: .map,
                 mascotFrames: ["Mascot Talking", "Mascot Neutral", "Mascot Talking"],
                 titleKey: "onboarding.page2.title",
                 bodyKey:  "onboarding.page2.body"),
        PageData(visual: .symbol("rectangle.stack.fill",
                                  Color(red: 0.10, green: 0.55, blue: 0.78)),
                 mascotFrames: ["Mascot Neutral", "Mascot Talking"],
                 titleKey: "onboarding.page3.title",
                 bodyKey:  "onboarding.page3.body"),
        PageData(visual: .symbol("checkmark.seal.fill",
                                  Color(red: 0.28, green: 0.76, blue: 0.42)),
                 mascotFrames: ["Mascot Cheer", "Mascot Waving", "Mascot Cheer"],
                 titleKey: "onboarding.page4.title",
                 bodyKey:  "onboarding.page4.body"),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sfondo a gradiente cielo/oceano
                LinearGradient(colors: [skyTop, skyBottom],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                // Stelle decorative
                starsOverlay

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

    // MARK: - Stella decorativa

    private var starsOverlay: some View {
        GeometryReader { geo in
            ForEach(0..<18, id: \.self) { i in
                let fi = Double(i)
                let x  = (sin(fi * 3.71 + 1.2) * 0.5 + 0.5) * geo.size.width
                let y  = (sin(fi * 2.13 + 0.7) * 0.5 + 0.5) * geo.size.height * 0.55
                let sz = CGFloat(2 + (sin(fi * 5.3) * 0.5 + 0.5) * 3)

                Circle()
                    .fill(Color.white.opacity(0.30 + (sin(fi * 1.9) * 0.5 + 0.5) * 0.25))
                    .frame(width: sz, height: sz)
                    .position(x: x, y: y)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Pagina

    private func pageView(_ page: PageData, geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Elemento visivo principale
            visualElement(page.visual, geo: geo)
                .padding(.bottom, 28)

            // Mascot + speech bubble
            MascotGuideView(
                imageName: page.mascotFrames[0],
                animatedImageNames: page.mascotFrames,
                message: lm.t(page.bodyKey),
                imageHeight: min(geo.size.height * 0.17, 140),
                bubbleFont: .system(.title3, design: .rounded)
            )
            .padding(.horizontal, 36)

            // Titolo sotto
            Text(lm.t(page.titleKey))
                .font(.system(.title2, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .padding(.top, 20)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)

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
                .shadow(color: Color(red: 0.10, green: 0.55, blue: 0.78).opacity(0.6),
                        radius: 18, y: 6)
                .accessibilityHidden(true)
        case .map:
            Image("mappa")
                .resizable()
                .scaledToFill()
                .frame(width: min(geo.size.width * 0.55, 380), height: maxH)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.30), lineWidth: 2))
                .shadow(color: .black.opacity(0.40), radius: 14, y: 6)
                .accessibilityHidden(true)
        case .symbol(let name, let color):
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: maxH, height: maxH)
                Circle()
                    .stroke(color.opacity(0.35), lineWidth: 2)
                    .frame(width: maxH, height: maxH)
                Image(systemName: name)
                    .font(.system(size: maxH * 0.42, weight: .bold))
                    .foregroundStyle(color)
            }
            .shadow(color: color.opacity(0.40), radius: 16, y: 4)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Barra inferiore

    private var bottomBar: some View {
        HStack(alignment: .center) {
            Button(lm.t("onboarding.skip")) { onFinish() }
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.65))
                .opacity(currentPage < pages.count - 1 ? 1 : 0)
                .disabled(currentPage == pages.count - 1)
                .frame(minWidth: 80, alignment: .leading)

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage
                              ? Color.white
                              : Color.white.opacity(0.30))
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
                Text(currentPage < pages.count - 1
                     ? lm.t("onboarding.next")
                     : lm.t("onboarding.start"))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.10, green: 0.55, blue: 0.78))
                            .shadow(color: Color(red: 0.10, green: 0.55, blue: 0.78).opacity(0.5),
                                    radius: 10, y: 4)
                    )
            }
            .buttonStyle(.plain)
            .frame(minWidth: 80, alignment: .trailing)
        }
    }
}

