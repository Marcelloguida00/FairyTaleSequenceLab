import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIPageViewController with a realistic 3D page curl effect.
struct PageCurlBookView<Page: View>: UIViewControllerRepresentable {
    var pages: [Page]
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.mid.rawValue]
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        pageViewController.isDoubleSided = true

        // Set initial view controllers
        if pages.isEmpty { return pageViewController }
        
        let initialViewControllers = context.coordinator.viewControllers(for: currentPage)
        pageViewController.setViewControllers(
            initialViewControllers,
            direction: .forward,
            animated: false,
            completion: nil
        )

        return pageViewController
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateControllers(with: pages)
        
        // If the UIPageViewController is empty (e.g. loaded before pages were generated), initialize it now
        if uiViewController.viewControllers?.isEmpty ?? true, !pages.isEmpty {
            let initialViewControllers = context.coordinator.viewControllers(for: currentPage)
            uiViewController.setViewControllers(
                initialViewControllers,
                direction: .forward,
                animated: false,
                completion: nil
            )
            return
        }
        
        // Handle programmatic page changes
        if let currentVC = uiViewController.viewControllers?.first,
           let currentIndex = context.coordinator.controllers.firstIndex(of: currentVC) {
            
            let currentLeftIndex = currentIndex % 2 == 0 ? currentIndex : currentIndex - 1
            let targetLeftIndex = currentPage % 2 == 0 ? currentPage : currentPage - 1
            
            if currentLeftIndex != targetLeftIndex {
                context.coordinator.turnToPage(targetLeftIndex, in: uiViewController)
            }
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlBookView
        var controllers: [UIViewController] = []
        var isAnimating = false

        init(_ parent: PageCurlBookView) {
            self.parent = parent
            super.init()
            self.updateControllers(with: parent.pages)
        }
        
        func turnToPage(_ targetLeft: Int, in pageViewController: UIPageViewController) {
            guard !isAnimating else { return }
            guard let currentVC = pageViewController.viewControllers?.first,
                  let currentIndex = controllers.firstIndex(of: currentVC) else { return }
            
            let currentLeft = currentIndex % 2 == 0 ? currentIndex : currentIndex - 1
            if currentLeft == targetLeft { return }
            
            isAnimating = true
            let direction: UIPageViewController.NavigationDirection = targetLeft > currentLeft ? .forward : .reverse
            
            // Flip 2 pages at a time (one full spread)
            let step = direction == .forward ? 2 : -2
            let nextLeft = currentLeft + step
            
            // If the next step overshoots, clamp it to target
            let actualNextLeft = (direction == .forward) ? min(nextLeft, targetLeft) : max(nextLeft, targetLeft)
            
            let vcs = viewControllers(for: actualNextLeft)
            pageViewController.setViewControllers(vcs, direction: direction, animated: true) { [weak self] finished in
                DispatchQueue.main.async {
                    self?.isAnimating = false
                    if finished && actualNextLeft != targetLeft {
                        self?.turnToPage(targetLeft, in: pageViewController)
                    } else if finished && actualNextLeft == targetLeft {
                        // Ensure parent's binding is fully synced
                        self?.parent.currentPage = actualNextLeft
                    }
                }
            }
        }
        
        func updateControllers(with newPages: [Page]) {
            if controllers.count != newPages.count {
                controllers = newPages.enumerated().map { index, view in
                    let hc = UIHostingController(rootView: view)
                    hc.view.backgroundColor = .clear
                    hc.view.tag = index
                    return hc
                }
            } else {
                for (index, view) in newPages.enumerated() {
                    if let hc = controllers[index] as? UIHostingController<Page> {
                        hc.rootView = view
                    }
                }
            }
        }

        func viewControllers(for index: Int) -> [UIViewController] {
            guard controllers.count > 0 else { return [] }
            
            // For spineLocation = .mid, we need two controllers.
            // Even index on the left, odd on the right.
            let leftIndex = index % 2 == 0 ? index : index - 1
            let rightIndex = leftIndex + 1
            
            let leftVC = controllers.indices.contains(leftIndex) ? controllers[leftIndex] : emptyController()
            let rightVC = controllers.indices.contains(rightIndex) ? controllers[rightIndex] : emptyController()
            
            return [leftVC, rightVC]
        }
        
        private func emptyController() -> UIViewController {
            let vc = UIViewController()
            vc.view.backgroundColor = .clear
            return vc
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index == 0 {
                return nil
            }
            return controllers[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index == controllers.count - 1 {
                return nil
            }
            return controllers[index + 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            if completed,
               let visibleVC = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(of: visibleVC) {
                parent.currentPage = index
            }
        }
    }
}

struct FairyTaleInfo {
    let title: String
    let color: Color
    let iconName: String
}

struct FairyTaleBookmark: Identifiable {
    let id = UUID()
    let info: FairyTaleInfo
    let startPageIndex: Int
}

private struct BookmarkIconView: View {
    let iconName: String
    let size: CGFloat
    let yOffset: CGFloat

    private static let strokeOffsets: [CGPoint] = [
        CGPoint(x: -1.2, y: 0),
        CGPoint(x: 1.2, y: 0),
        CGPoint(x: 0, y: -1.2),
        CGPoint(x: 0, y: 1.2),
        CGPoint(x: -1.2, y: -1.2),
        CGPoint(x: 1.2, y: -1.2),
        CGPoint(x: -1.2, y: 1.2),
        CGPoint(x: 1.2, y: 1.2)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(Self.strokeOffsets.enumerated()), id: \.offset) { _, offset in
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(Color.white)
                    .offset(x: offset.x, y: offset.y + yOffset)
            }

            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(y: yOffset)
        }
    }
}

struct StoryScene: Identifiable {
    let id: Int
    let titleKey: String
    let text1Key: String
    let text2Key: String
    let introImageName: String
    let rewardImageName: String
}

enum PageLayoutType {
    case fullText
    case textTopImageBottom
    case imageTopTextBottom
    case textLeftImageRight
    case imageLeftTextRight
    case textTopImageCenterTextBottom
    case imageTopLeftTextWrap
    case imageTopRightTextWrap
    case textTopImageBottomLeftTextWrap
    case textTopImageBottomRightTextWrap
    case poemCenterText
    case gatheredBottomRight
    case gatheredTopLeft
}

struct PageContent {
    let layout: PageLayoutType
    let textChunk1: String
    let textChunk2: String?
    let imageName: String?
}

struct BookView: View {
    static let redHoodScenes = [
        StoryScene(
            id: 1,
            titleKey: "story.redhood.scene1.title",
            text1Key: "story.redhood.scene1.text1",
            text2Key: "story.redhood.scene1.text2",
            introImageName: "MotherBasket",
            rewardImageName: "RedHoodWalking"
        ),
        StoryScene(
            id: 2,
            titleKey: "story.redhood.scene2.title",
            text1Key: "story.redhood.scene2.text1",
            text2Key: "story.redhood.scene2.text2",
            introImageName: "RedHoodWolf",
            rewardImageName: "Reward evento 2"
        ),
        StoryScene(
            id: 3,
            titleKey: "story.redhood.scene3.title",
            text1Key: "story.redhood.scene3.text1",
            text2Key: "story.redhood.scene3.text2",
            introImageName: "Introduzione_3",
            rewardImageName: "Fine 3"
        ),
        StoryScene(
            id: 4,
            titleKey: "story.redhood.scene4.title",
            text1Key: "story.redhood.scene4.text1",
            text2Key: "story.redhood.scene4.text2",
            introImageName: "3_1",
            rewardImageName: "Fine 3"
        ),
        StoryScene(
            id: 5,
            titleKey: "story.redhood.scene5.title",
            text1Key: "story.redhood.scene5.text1",
            text2Key: "story.redhood.scene5.text2",
            introImageName: "3_3",
            rewardImageName: "Fine 3"
        ),
        StoryScene(
            id: 6,
            titleKey: "story.redhood.scene6.title",
            text1Key: "story.redhood.scene6.text1",
            text2Key: "story.redhood.scene6.text2",
            introImageName: "Introduzione 2 evento",
            rewardImageName: "Fine 3"
        ),
        StoryScene(
            id: 7,
            titleKey: "story.redhood.scene7.title",
            text1Key: "story.redhood.scene7.text1",
            text2Key: "story.redhood.scene7.text2",
            introImageName: "3_3",
            rewardImageName: "Fine 3"
        ),
        StoryScene(
            id: 8,
            titleKey: "story.redhood.scene8.title",
            text1Key: "story.redhood.scene8.text1",
            text2Key: "story.redhood.scene8.text2",
            introImageName: "Fine 3",
            rewardImageName: "Fine primo evento"
        )
    ]

    let onDismiss: () -> Void
    @EnvironmentObject private var lm: LanguageManager
    @State private var completedEvents: [EventData] = []
    @State private var currentPage = 0
    @State private var bookPages: [AnyView] = []
    @State private var bookmarks: [FairyTaleBookmark] = []
    @State private var lastIsCompact: Bool? = nil
    @State private var isARBookOpen = false
    @State private var pageTexts: [String] = []
    
    var body: some View {
        GeometryReader { geom in
            let isCompact = geom.size.width < 600
            
            ZStack {
                // Background
                Color.black.opacity(0.8).ignoresSafeArea()
                
                ZStack(alignment: .topTrailing) {
                    OpenBookBackground()
                    
                    PageCurlBookView(pages: bookPages, currentPage: $currentPage)
                    
                    // Bookmarks UI
                    VStack(spacing: isCompact ? 6 : 8) {
                        ForEach(bookmarks) { bookmark in
                            Button(action: {
                                currentPage = bookmark.startPageIndex
                            }) {
                                ZStack {
                                    Path { path in
                                        let w: CGFloat = isCompact ? 24 : 40
                                        let h: CGFloat = isCompact ? 32 : 50
                                        let arrow: CGFloat = isCompact ? 25 : 40
                                        path.move(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: w, y: 0))
                                        path.addLine(to: CGPoint(x: w, y: h))
                                        path.addLine(to: CGPoint(x: w / 2, y: arrow))
                                        path.addLine(to: CGPoint(x: 0, y: h))
                                        path.closeSubpath()
                                    }
                                    .fill(LinearGradient(gradient: Gradient(colors: [bookmark.info.color.opacity(0.9), bookmark.info.color.opacity(0.7)]), startPoint: .leading, endPoint: .trailing))
                                    .frame(width: isCompact ? 24 : 40, height: isCompact ? 32 : 50)
                                    .shadow(color: .black.opacity(0.4), radius: 2, x: 2, y: 2)
                                    .accessibilityHidden(true)
                                    
                                    BookmarkIconView(
                                        iconName: bookmark.info.iconName,
                                        size: isCompact ? 14 : 22,
                                        yOffset: isCompact ? -3 : -5
                                    )
                                    .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(bookmark.info.title)
                            .gameMinimumTouchTarget(
                                minWidth: max(isCompact ? 24 : 40, GameButtonMetrics.minimumTouchTarget),
                                minHeight: max(isCompact ? 32 : 50, GameButtonMetrics.minimumTouchTarget)
                            )
                            .offset(x: isBookmarkActive(bookmark) ? (isCompact ? -12 : -20) : 0)
                            .animation(.spring(), value: currentPage)
                        }
                    }
                    .offset(x: isCompact ? 15 : 30, y: isCompact ? 10 : 20)
                }
                .aspectRatio(1.5, contentMode: .fit)
                .padding(isCompact ? 12 : 50)
                
                // Top actions
                VStack {
                    HStack {
                        Spacer()

                        GameCircleButton(
                            systemImage: "xmark",
                            size: isCompact ? 30 : 40,
                            iconSize: isCompact ? 14 : 18,
                            action: onDismiss
                        )
                        .accessibilityLabel(lm.t("button.done"))
                        .padding(isCompact ? 12 : 20)
                    }
                    Spacer()
                }

                if isARBookOpen {
                    ARBookView(cards: arStoryCards, chapterText: currentChapterText) {
                        withAnimation(.easeInOut(duration: 0.24)) {
                            isARBookOpen = false
                        }
                    }
                    .environmentObject(lm)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .onAppear {
                let initialCompact = geom.size.width < 600
                self.lastIsCompact = initialCompact
                loadCompletedEvents(isCompact: initialCompact)
            }
            .onDisappear {
                AppSpeechSynthesizer.shared.stop()
            }
            .onChange(of: lm.currentLanguage) { _, _ in
                if let isCompact = lastIsCompact {
                    loadCompletedEvents(isCompact: isCompact)
                }
            }
            .onChange(of: geom.size.width) { _, _ in
                let isCompact = geom.size.width < 600
                if isCompact != lastIsCompact {
                    self.lastIsCompact = isCompact
                    buildPagesAndBookmarks(isCompact: isCompact)
                }
            }
            .onChange(of: currentPage) { _, _ in
                speakCurrentPage()
            }
        }
    }

    private func currentScene() -> StoryScene? {
        let isDyslexiaEnabled = UserDefaults.standard.bool(forKey: AppFontSettings.dyslexiaFontKey)
        let isCompact = lastIsCompact ?? false
        let maxCompletedId = completedEvents.map(\.id).max() ?? 0
        let visibleScenes = Array(BookView.redHoodScenes.prefix(maxCompletedId))
        
        var pageIndex = 0
        for scene in visibleScenes {
            let startPage = pageIndex
            pageIndex += 1 // intro page
            
            let fullText = lm.t(scene.text1Key) + "\n\n" + lm.t(scene.text2Key)
            let textPages = paginateText(fullText, isDyslexiaEnabled: isDyslexiaEnabled, isCompact: isCompact)
            
            pageIndex += textPages.count
            if textPages.count % 2 != 0 { pageIndex += 1 }
            pageIndex += 1 // reward page
            
            if currentPage >= startPage && currentPage < pageIndex {
                return scene
            }
        }
        return visibleScenes.last
    }

    private var arStoryCards: [ARStoryCard] {
        guard let scene = currentScene(), let event = completedEvents.first(where: { $0.id == scene.id }) else { return [] }
        return event.cards
            .sorted { $0.correctPosition < $1.correctPosition }
            .map { card in
                ARStoryCard(
                    id: "\(event.id)-\(card.id)",
                    eventID: event.id,
                    sequenceNumber: card.correctPosition + 1,
                    eventTitle: event.bannerTitle,
                    imageName: card.imageName,
                    description: card.description
                )
            }
    }
    
    private var currentChapterText: String {
        guard let scene = currentScene() else { return "" }
        return lm.t(scene.text1Key) + "\n\n" + lm.t(scene.text2Key)
    }
    
    private func isBookmarkActive(_ bookmark: FairyTaleBookmark) -> Bool {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return false }
        let startPage = bookmark.startPageIndex
        let endPage = (index < bookmarks.count - 1) ? bookmarks[index + 1].startPageIndex : bookPages.count
        return currentPage >= startPage && currentPage < endPage
    }
    
    private func loadCompletedEvents(isCompact: Bool) {
        let savedLevels = Set(UserDefaults.standard.array(forKey: "completedRedHoodLevels") as? [Int] ?? [])
        let bundle = lm.bundle
        var loadedEvents: [EventData] = []
        
        let allRedHoodIds = Array(0...EventLoader.maxEventId(from: bundle))
        for id in allRedHoodIds {
            if savedLevels.contains(id), let event = EventLoader.event(id: id, from: bundle) {
                loadedEvents.append(event)
            }
        }
        self.completedEvents = loadedEvents
        buildPagesAndBookmarks(isCompact: isCompact)
    }
    
    private func paginateText(_ text: String, isDyslexiaEnabled: Bool, isCompact: Bool) -> [String] {
        // Split by words to allow continuous flowing text without forcing double line breaks
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        let maxChars = isCompact 
            ? (isDyslexiaEnabled ? 130 : 180) 
            : (isDyslexiaEnabled ? 180 : 250)
            
        var pages: [String] = []
        var currentPage = ""
        
        for word in words {
            // Respect intentional double line breaks if we added them to separate events
            if word == "[EVENT_BREAK]" {
                if !currentPage.isEmpty {
                    pages.append(currentPage)
                    currentPage = ""
                }
                continue
            }
            
            if currentPage.isEmpty {
                currentPage = word
            } else {
                if currentPage.count + word.count + 1 > maxChars {
                    pages.append(currentPage)
                    currentPage = word
                } else {
                    currentPage += " " + word
                }
            }
        }
        
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }
        
        return pages
    }
    
    private func generateEditorialPages(text: String, availableImages: [String], isDyslexiaEnabled: Bool, isCompact: Bool) -> [PageContent] {
        var sentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { substring, _, _, _ in
            if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                sentences.append(s)
            }
        }
        var pages: [PageContent] = []
        var currentImageIndex = 0
        var currentSentenceIndex = 0
        var pageIndex = 0
        
        let layouts: [PageLayoutType] = [
            .textTopImageBottom,
            .imageTopTextBottom,
            .fullText,
            .imageTopTextBottom,
            .gatheredBottomRight,
            .textTopImageBottom,
            .poemCenterText,
            .imageTopRightTextWrap,
            .textTopImageBottom,
            .textTopImageBottom,
            .fullText
        ]
        
        // Define relative capacity weights for each layout type
        let layoutWeights: [PageLayoutType: Double] = [
            .fullText: 1.0,
            .poemCenterText: 0.5,
            .gatheredBottomRight: 0.5,
            .gatheredTopLeft: 0.5,
            .textTopImageBottom: 0.4,
            .imageTopTextBottom: 0.4,
            .textLeftImageRight: 0.4,
            .imageLeftTextRight: 0.4,
            .textTopImageCenterTextBottom: 0.5,
            .imageTopLeftTextWrap: 0.6,
            .imageTopRightTextWrap: 0.6,
            .textTopImageBottomLeftTextWrap: 0.6,
            .textTopImageBottomRightTextWrap: 0.6
        ]
        
        let totalWeight = layouts.reduce(0.0) { $0 + (layoutWeights[$1] ?? 1.0) }
        let totalChars = sentences.reduce(0) { $0 + $1.count + 1 }
        var remainingTotalChars = totalChars
        var remainingWeight = totalWeight
        
        while currentSentenceIndex < sentences.count {
            let layout = layouts[pageIndex % layouts.count]
            pageIndex += 1
            
            let currentWeight = layoutWeights[layout] ?? 1.0
            
            var maxChars = 0
            if remainingWeight > 0 {
                maxChars = Int((currentWeight / remainingWeight) * Double(remainingTotalChars))
            } else {
                maxChars = remainingTotalChars
            }
            
            if maxChars < 50 { maxChars = 50 }
            
            var targetChars1 = maxChars
            var requiresTwoChunks = false
            
            switch layout {
            case .textTopImageCenterTextBottom:
                targetChars1 = maxChars / 2
                requiresTwoChunks = true
            case .imageTopLeftTextWrap, .imageTopRightTextWrap:
                targetChars1 = Int(Double(maxChars) * 0.35)
                requiresTwoChunks = true
            case .textTopImageBottomLeftTextWrap, .textTopImageBottomRightTextWrap:
                targetChars1 = Int(Double(maxChars) * 0.5)
                requiresTwoChunks = true
            default:
                break
            }
            
            var chunk1 = ""
            var chunk2: String? = nil
            
            while currentSentenceIndex < sentences.count {
                let sentence = sentences[currentSentenceIndex]
                if chunk1.isEmpty {
                    chunk1 = sentence
                } else if chunk1.count + sentence.count + 1 <= targetChars1 {
                    chunk1 += " " + sentence
                } else {
                    break
                }
                currentSentenceIndex += 1
            }
            
            if requiresTwoChunks {
                var chunk2Text = ""
                let targetChars2 = maxChars - chunk1.count
                while currentSentenceIndex < sentences.count {
                    let sentence = sentences[currentSentenceIndex]
                    if chunk2Text.isEmpty {
                        chunk2Text = sentence
                    } else if chunk2Text.count + sentence.count + 1 <= targetChars2 {
                        chunk2Text += " " + sentence
                    } else {
                        break
                    }
                    currentSentenceIndex += 1
                }
                if !chunk2Text.isEmpty {
                    chunk2 = chunk2Text
                }
            }
            
            if pageIndex == layouts.count {
                while currentSentenceIndex < sentences.count {
                    let sentence = sentences[currentSentenceIndex]
                    if requiresTwoChunks {
                        chunk2 = (chunk2 ?? "") + (chunk2 == nil ? "" : " ") + sentence
                    } else {
                        chunk1 += " " + sentence
                    }
                    currentSentenceIndex += 1
                }
            } else {
                let consumed = chunk1.count + (chunk2 == nil ? 0 : chunk2!.count + 1)
                remainingTotalChars -= consumed
                remainingWeight -= currentWeight
            }
            let layoutUsesImage: Bool
            switch layout {
            case .fullText, .poemCenterText, .gatheredBottomRight, .gatheredTopLeft:
                layoutUsesImage = false
            default:
                layoutUsesImage = true
            }
            
            var imageName: String? = nil
            if pageIndex == 3 {
                imageName = "Sequenza 2 evento 3"
            } else if pageIndex == 4 {
                imageName = "event3_card2"
            } else if pageIndex == 5 {
                imageName = "scene4_card1"
            } else if pageIndex == 6 {
                imageName = "scene4_card4"
            } else if pageIndex == 8 {
                imageName = "scene6_card2"
            } else if pageIndex == 9 {
                imageName = "scene8_card1"
            } else if pageIndex == 10 {
                imageName = "scene8_card2"
            } else if pageIndex == 11 {
                imageName = "scene8_card3"
            } else if layoutUsesImage && currentImageIndex < availableImages.count {
                imageName = availableImages[currentImageIndex]
                currentImageIndex += 1
            }
            
            let finalLayout = (layoutUsesImage && imageName == nil) ? .fullText : layout
            let finalChunk1 = (finalLayout == .fullText && chunk2 != nil) ? (chunk1 + " " + chunk2!) : chunk1
            let finalChunk2 = (finalLayout == .fullText) ? nil : chunk2
            
            pages.append(PageContent(layout: finalLayout, textChunk1: finalChunk1, textChunk2: finalChunk2, imageName: imageName))
        }
        
        return pages
    }
    
    private func buildPagesAndBookmarks(isCompact: Bool) {
        var newPages: [AnyView] = []
        var newBookmarks: [FairyTaleBookmark] = []
        var newPageTexts: [String] = []
        
        let isDyslexiaEnabled = UserDefaults.standard.bool(forKey: AppFontSettings.dyslexiaFontKey)
        // Made padding smaller to make pages more compact
        let pagePadding: CGFloat = isCompact ? 10 : 24
        
        let titleFont = isDyslexiaEnabled ? 
            (isCompact ? Font.app(.headline, weight: .bold) : Font.app(.title, weight: .bold)) :
            (isCompact ? Font.custom("Alegreya", size: 24, relativeTo: .title).weight(.bold) : Font.custom("Alegreya", size: 36, relativeTo: .title).weight(.bold))
            
        let textFont = isDyslexiaEnabled ? 
            (isCompact ? Font.app(.subheadline, weight: .regular) : Font.app(.title3, weight: .regular)) :
            (isCompact ? Font.custom("Alegreya", size: 18, relativeTo: .body) : Font.custom("Alegreya", size: 26, relativeTo: .body))
            
        let dropCapFont = isDyslexiaEnabled ?
            (isCompact ? Font.app(.largeTitle, weight: .bold) : Font.app(size: 48, weight: .bold)) :
            (isCompact ? Font.custom("Alegreya", size: 40, relativeTo: .largeTitle).weight(.bold) : Font.custom("Alegreya", size: 60, relativeTo: .largeTitle).weight(.bold))
            
        let lineSpacing: CGFloat = isCompact ? 3 : 6
        
        func pageContainer<Content: View>(isLeft: Bool, pageNumber: Int? = nil, showVines: Bool = false, @ViewBuilder content: () -> Content) -> AnyView {
            AnyView(
                ZStack {
                    // Color matching the page edges (stack)
                    Color(red: 0.85, green: 0.8, blue: 0.65)
                    
                    PageBackgroundDecal(pageNumber: pageNumber ?? 1)
                        .allowsHitTesting(false)
                    
                    FairyTaleFrame(isLeft: isLeft, pageNumber: pageNumber ?? 1, showVines: showVines)
                        .allowsHitTesting(false)
                    
                    content()
                        .padding(pagePadding)
                    
                    HStack(spacing: 0) {
                        if isLeft {
                            Spacer(minLength: 0)
                            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.4), .clear]), startPoint: .trailing, endPoint: .leading)
                                .frame(width: isCompact ? 20 : 40)
                        } else {
                            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.4), .clear]), startPoint: .leading, endPoint: .trailing)
                                .frame(width: isCompact ? 20 : 40)
                            Spacer(minLength: 0)
                        }
                    }
                    .allowsHitTesting(false)
                        
                    if let pageNum = pageNumber {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(pageNum)")
                                    .font(textFont)
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                                    .padding(.bottom, isCompact ? 16 : 24)
                                Spacer()
                            }
                        }
                    }
                }
                .clipped()
            )
        }
        
        func addPlaceholder(title: String, subtitle: String) {
            let emptyLeft = pageContainer(isLeft: true) {
                VStack(spacing: isCompact ? 10 : 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(isCompact ? .title2 : .largeTitle))
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                        .accessibilityHidden(true)
                    Text(subtitle)
                        .font(isDyslexiaEnabled ? .app(.subheadline) : Font.custom("Alegreya", size: isCompact ? 18 : 26, relativeTo: .body))
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                        .multilineTextAlignment(.center)
                }
            }
            let emptyRight = pageContainer(isLeft: false) {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(titleFont)
                        .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.1))
                    Spacer()
                }
            }
            newPages.append(emptyLeft)
            newPageTexts.append(subtitle)
            newPages.append(emptyRight)
            newPageTexts.append(title)
        }
        
        let redRidingHood = FairyTaleInfo(
            title: lm.t("map.region.red_riding_hood"),
            color: Color(red: 0.7, green: 0.1, blue: 0.1),
            iconName: "RedHoodBookmarkIcon"
        )

        newBookmarks.append(FairyTaleBookmark(info: redRidingHood, startPageIndex: 0))

        let maxCompletedId = completedEvents.map(\.id).max() ?? 0
        var maxUnlockedPage = 2
        switch maxCompletedId {
        case 1: maxUnlockedPage = 4
        case 2: maxUnlockedPage = 5
        case 3: maxUnlockedPage = 6
        case 4: maxUnlockedPage = 7
        case 5: maxUnlockedPage = 9
        case 6: maxUnlockedPage = 10
        case 7: maxUnlockedPage = 12
        case 8...: maxUnlockedPage = 100
        default: maxUnlockedPage = 2
        }

        if completedEvents.isEmpty {
            addPlaceholder(title: redRidingHood.title, subtitle: lm.t("book.placeholder.play_to_unlock"))
        } else {
            let visibleScenes = BookView.redHoodScenes

            if visibleScenes.isEmpty {
                addPlaceholder(title: redRidingHood.title, subtitle: lm.t("book.placeholder.play_to_unlock"))
            } else {
                let textColors = Color(red: 0.25, green: 0.15, blue: 0.1) // Dark warm brown
                let dropCapColor = Color(red: 0.6, green: 0.1, blue: 0.1) // Deep Red
                
                // --- Pagina Immagine (Sinistra) e Pagina Titolo (Destra) ---
                let insideCover = pageContainer(isLeft: true, pageNumber: nil, showVines: true) {
                    GeometryReader { geo in
                        Image("FairytaleTitleLandscape")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .mask(
                                Rectangle()
                                    .fill(Color.black)
                                    .padding(EdgeInsets(
                                        top: isCompact ? 20 : 40,
                                        leading: isCompact ? 20 : 40,
                                        bottom: isCompact ? 20 : 40,
                                        trailing: -(isCompact ? 60 : 120)
                                    ))
                                    .blur(radius: isCompact ? 30 : 60)
                            )
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                    .padding(-pagePadding) // Annulla il padding per occupare tutta la pagina e sovrapporsi alla cornice
                }
                
                let titleCover = pageContainer(isLeft: false, pageNumber: nil, showVines: true) {
                    ZStack {
                        GeometryReader { geo in
                            Image("FairytaleTitleBackground")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .mask(
                                    Rectangle()
                                        .fill(Color.black)
                                        .padding(EdgeInsets(
                                            top: isCompact ? 20 : 40,
                                            leading: -(isCompact ? 60 : 120),
                                            bottom: isCompact ? 20 : 40,
                                            trailing: isCompact ? 20 : 40
                                        ))
                                        .blur(radius: isCompact ? 30 : 60)
                                )
                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        }
                    }
                    .padding(-pagePadding)
                }
                
                newPages.append(insideCover)
                newPageTexts.append("")
                newPages.append(titleCover)
                newPageTexts.append(redRidingHood.title)
                // ------------------------------------------
                
                var pageIndex = newPages.count
                
                var fullContinuousText = ""
                var availableImages: [String] = []
                
                for scene in visibleScenes {
                    let sceneText1 = lm.t(scene.text1Key).trimmingCharacters(in: .whitespacesAndNewlines)
                    let sceneText2 = lm.t(scene.text2Key).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !sceneText1.isEmpty {
                        fullContinuousText += (fullContinuousText.isEmpty ? "" : " ") + sceneText1
                    }
                    if !sceneText2.isEmpty {
                        fullContinuousText += (fullContinuousText.isEmpty ? "" : " ") + sceneText2
                    }
                    
                    if UIImage(named: scene.introImageName) != nil {
                        availableImages.append(scene.introImageName)
                    }
                    if UIImage(named: scene.rewardImageName) != nil {
                        availableImages.append(scene.rewardImageName)
                    }
                }
                
                var editorialPages = generateEditorialPages(
                    text: fullContinuousText, 
                    availableImages: availableImages, 
                    isDyslexiaEnabled: isDyslexiaEnabled, 
                    isCompact: isCompact
                )
                
                // Sposta le prime frasi da pagina 5 (index 2) a pagina 4 (index 1) per far spazio al testo del lupo
                if editorialPages.count > 2 {
                    var p4Text = editorialPages[1].textChunk1
                    let p5Text = editorialPages[2].textChunk1
                    
                    var p5Sentences: [String] = []
                    p5Text.enumerateSubstrings(in: p5Text.startIndex..<p5Text.endIndex, options: .bySentences) { substring, _, _, _ in
                        if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                            p5Sentences.append(s)
                        }
                    }
                    
                    let numSentencesToMove = 3
                    if p5Sentences.count > numSentencesToMove {
                        let movedSentences = p5Sentences.prefix(numSentencesToMove).joined(separator: " ")
                        p4Text = p4Text + (p4Text.isEmpty ? "" : " ") + movedSentences
                        let newP5Text = p5Sentences.dropFirst(numSentencesToMove).joined(separator: " ")
                        
                        editorialPages[1] = PageContent(layout: editorialPages[1].layout, textChunk1: p4Text, textChunk2: editorialPages[1].textChunk2, imageName: editorialPages[1].imageName)
                        editorialPages[2] = PageContent(layout: editorialPages[2].layout, textChunk1: newP5Text, textChunk2: editorialPages[2].textChunk2, imageName: editorialPages[2].imageName)
                    }
                }
                
                // Sposta le ultime frasi da pagina 5 (index 2) a pagina 6 (index 3) per posizionare il dialogo del lupo
                if editorialPages.count > 3 {
                    let p5Text = editorialPages[2].textChunk1
                    var p6Text = editorialPages[3].textChunk1
                    
                    var p5Sentences: [String] = []
                    p5Text.enumerateSubstrings(in: p5Text.startIndex..<p5Text.endIndex, options: .bySentences) { substring, _, _, _ in
                        if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                            p5Sentences.append(s)
                        }
                    }
                    
                    let numSentencesToMoveToP6 = 2
                    if p5Sentences.count > numSentencesToMoveToP6 {
                        let movedToP6 = p5Sentences.suffix(numSentencesToMoveToP6).joined(separator: " ")
                        p6Text = movedToP6 + (p6Text.isEmpty ? "" : " ") + p6Text
                        let newP5Text = p5Sentences.dropLast(numSentencesToMoveToP6).joined(separator: " ")
                        
                        editorialPages[2] = PageContent(layout: editorialPages[2].layout, textChunk1: newP5Text, textChunk2: editorialPages[2].textChunk2, imageName: editorialPages[2].imageName)
                        editorialPages[3] = PageContent(layout: editorialPages[3].layout, textChunk1: p6Text, textChunk2: editorialPages[3].textChunk2, imageName: editorialPages[3].imageName)
                    }
                }
                
                // Sposta le prime 2 frasi da pagina 13 (index 10) a pagina 12 (index 9) e tronca il resto del testo dopo l'abbraccio
                if editorialPages.count > 10 {
                    var p12Text = editorialPages[9].textChunk1
                    let p13Text = editorialPages[10].textChunk1
                    
                    var p13Sentences: [String] = []
                    p13Text.enumerateSubstrings(in: p13Text.startIndex..<p13Text.endIndex, options: .bySentences) { substring, _, _, _ in
                        if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                            p13Sentences.append(s)
                        }
                    }
                    
                    let numSentencesToMoveToP12 = 2
                    if p13Sentences.count > numSentencesToMoveToP12 {
                        let movedToP12 = p13Sentences.prefix(numSentencesToMoveToP12).joined(separator: " ")
                        p12Text = p12Text + (p12Text.isEmpty ? "" : " ") + movedToP12
                        
                        // Prendi il testo fino all'abbraccio (altre 3 frasi)
                        let numSentencesToKeepOnP13 = 3
                        let keepOnP13 = p13Sentences.dropFirst(numSentencesToMoveToP12).prefix(numSentencesToKeepOnP13).joined(separator: " ")
                        
                        editorialPages[9] = PageContent(layout: editorialPages[9].layout, textChunk1: p12Text, textChunk2: editorialPages[9].textChunk2, imageName: editorialPages[9].imageName)
                        editorialPages[10] = PageContent(layout: editorialPages[10].layout, textChunk1: keepOnP13, textChunk2: editorialPages[10].textChunk2, imageName: editorialPages[10].imageName)
                    }
                }
                
                for (i, pageContent) in editorialPages.enumerated() {
                    let isFirstPage = (i == 0)
                    let imgHeight: CGFloat = isCompact ? 160 : 280
                    
                    let isLocked = (pageIndex + 1) > maxUnlockedPage
                    
                    let page = pageContainer(isLeft: pageIndex % 2 == 0, pageNumber: pageIndex + 1) {
                        VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                            
                            switch pageContent.layout {
                            case .fullText:
                                editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                    .padding(.horizontal, isCompact ? 20 : 35)
                                    .padding(.vertical, isCompact ? 10 : 15)
                                Spacer(minLength: 0)
                                if let imgName = pageContent.imageName {
                                    let pageNum = pageIndex + 1
                                    let needsOffset = [3, 8, 11, 12, 13].contains(pageNum)
                                    editorialImage(imgName: imgName, height: imgHeight, offsetY: needsOffset ? (isCompact ? 40 : 70) : 0)
                                }
                                
                            case .poemCenterText:
                                if pageIndex + 1 == 9 {
                                    editorialImage(imgName: "event5_card2", height: imgHeight * 0.8)
                                        .padding(.top, isCompact ? 10 : 20)
                                } else {
                                    Spacer()
                                }
                                
                                HStack {
                                    Spacer(minLength: isCompact ? 30 : 60)
                                    editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing, alignment: .center)
                                        .multilineTextAlignment(.center)
                                    Spacer(minLength: isCompact ? 30 : 60)
                                }
                                
                                if pageIndex + 1 == 9 {
                                    editorialImage(imgName: "event5_card4", height: imgHeight * 0.8)
                                        .padding(.bottom, isCompact ? 10 : 20)
                                } else {
                                    Spacer()
                                }
                                
                            case .gatheredBottomRight:
                                if let imgName = pageContent.imageName {
                                    editorialImage(imgName: imgName, height: imgHeight)
                                        .padding(.top, isCompact ? 10 : 20)
                                }
                                Spacer()
                                HStack {
                                    Spacer(minLength: isCompact ? 60 : 120)
                                    editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing, alignment: .trailing)
                                        .multilineTextAlignment(.trailing)
                                }
                                .padding(.bottom, isCompact ? 20 : 40)
                                .padding(.trailing, isCompact ? 20 : 35)
                                
                            case .gatheredTopLeft:
                                HStack {
                                    editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: isCompact ? 60 : 120)
                                }
                                .padding(.top, isCompact ? 20 : 40)
                                .padding(.leading, isCompact ? 20 : 35)
                                Spacer()
                                
                            case .textTopImageBottom:
                                editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                    .padding(.horizontal, isCompact ? 20 : 35)
                                    .padding(.vertical, isCompact ? 10 : 15)
                                Spacer(minLength: 10)
                                if let imgName = pageContent.imageName {
                                    let pageNum = pageIndex + 1
                                    let needsOffset = [3, 8, 11, 12, 13].contains(pageNum)
                                    editorialImage(imgName: imgName, height: imgHeight, offsetY: needsOffset ? (isCompact ? 40 : 70) : 0)
                                }
                                Spacer(minLength: 0)
                                
                            case .imageTopTextBottom:
                                if let imgName = pageContent.imageName {
                                    editorialImage(imgName: imgName, height: imgHeight)
                                        .padding(.top, isCompact ? 10 : 20)
                                }
                                Spacer(minLength: 10)
                                editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                    .padding(.horizontal, isCompact ? 20 : 35)
                                    .padding(.vertical, isCompact ? 10 : 15)
                                Spacer(minLength: 0)
                                
                            case .textLeftImageRight:
                                HStack(alignment: .top, spacing: 15) {
                                    editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                    if let imgName = pageContent.imageName {
                                        Image(imgName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: isCompact ? 120 : 200, height: isCompact ? 120 : 200)
                                            .mask(
                                                OrganicBlobMask()
                                                    .padding(5)
                                                    .blur(radius: 8)
                                            )
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding(.horizontal, isCompact ? 20 : 35)
                                .padding(.vertical, isCompact ? 10 : 15)
                                Spacer(minLength: 0)
                                
                            case .imageLeftTextRight:
                                HStack(alignment: .top, spacing: 15) {
                                    if let imgName = pageContent.imageName {
                                        Image(imgName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: isCompact ? 120 : 200, height: isCompact ? 120 : 200)
                                            .mask(
                                                OrganicBlobMask()
                                                    .padding(5)
                                                    .blur(radius: 8)
                                            )
                                            .accessibilityHidden(true)
                                    }
                                    editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                }
                                .padding(.horizontal, isCompact ? 20 : 35)
                                .padding(.vertical, isCompact ? 10 : 15)
                                Spacer(minLength: 0)
                                
                            case .textTopImageCenterTextBottom:
                                editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                    .padding(.horizontal, isCompact ? 20 : 35)
                                    .padding(.top, isCompact ? 10 : 15)
                                Spacer(minLength: 5)
                                if let imgName = pageContent.imageName {
                                    editorialImage(imgName: imgName, height: imgHeight * 0.8)
                                }
                                Spacer(minLength: 5)
                                if let chunk2 = pageContent.textChunk2 {
                                    editorialText(chunk: chunk2, isFirst: false, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                        .padding(.horizontal, isCompact ? 20 : 35)
                                        .padding(.bottom, isCompact ? 10 : 15)
                                }
                                Spacer(minLength: 0)
                                
                            case .imageTopLeftTextWrap:
                                VStack(alignment: .leading, spacing: isCompact ? 10 : 15) {
                                    HStack(alignment: .top, spacing: 15) {
                                        if let imgName = pageContent.imageName {
                                            Image(imgName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: isCompact ? 110 : 180)
                                                .mask(
                                                    OrganicBlobMask()
                                                        .padding(5)
                                                        .blur(radius: 8)
                                                )
                                                .accessibilityHidden(true)
                                        }
                                        editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                    }
                                    .padding(.horizontal, isCompact ? 20 : 35)
                                    .padding(.top, isCompact ? 10 : 15)
                                    
                                    if let chunk2 = pageContent.textChunk2 {
                                        editorialText(chunk: chunk2, isFirst: false, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                            .padding(.horizontal, isCompact ? 20 : 35)
                                            .padding(.bottom, isCompact ? 10 : 15)
                                    }
                                    Spacer(minLength: 0)
                                }
                                
                            case .imageTopRightTextWrap:
                                VStack(alignment: .leading, spacing: isCompact ? 10 : 15) {
                                    HStack(alignment: .top, spacing: 15) {
                                        editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                        if let imgName = pageContent.imageName {
                                            Image(imgName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: isCompact ? 110 : 180)
                                                .mask(
                                                    OrganicBlobMask()
                                                        .padding(5)
                                                        .blur(radius: 8)
                                                )
                                                .accessibilityHidden(true)
                                        }
                                    }
                                    .padding(.horizontal, isCompact ? 20 : 35)
                                    .padding(.top, isCompact ? 10 : 15)
                                    
                                    if let chunk2 = pageContent.textChunk2 {
                                        editorialText(chunk: chunk2, isFirst: false, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                            .padding(.horizontal, isCompact ? 20 : 35)
                                            .padding(.bottom, isCompact ? 10 : 15)
                                    }
                                    Spacer(minLength: 0)
                                    if pageIndex + 1 == 10 {
                                        editorialImage(imgName: "event7_card2", height: imgHeight)
                                            .padding(.bottom, isCompact ? 10 : 20)
                                    }
                                }
                                
                            case .textTopImageBottomLeftTextWrap:
                                VStack(alignment: .leading, spacing: isCompact ? 10 : 15) {
                                    editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                        .padding(.horizontal, isCompact ? 20 : 35)
                                        .padding(.top, isCompact ? 10 : 15)
                                        
                                    HStack(alignment: .top, spacing: 15) {
                                        if let imgName = pageContent.imageName {
                                            Image(imgName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: isCompact ? 110 : 180, height: isCompact ? 110 : 180)
                                                .mask(
                                                    OrganicBlobMask()
                                                        .padding(5)
                                                        .blur(radius: 8)
                                                )
                                                .accessibilityHidden(true)
                                        }
                                        if let chunk2 = pageContent.textChunk2 {
                                            editorialText(chunk: chunk2, isFirst: false, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                        }
                                    }
                                    .padding(.horizontal, isCompact ? 20 : 35)
                                    .padding(.bottom, isCompact ? 10 : 15)
                                    Spacer(minLength: 0)
                                }
                                
                            case .textTopImageBottomRightTextWrap:
                                VStack(alignment: .leading, spacing: isCompact ? 10 : 15) {
                                    editorialText(chunk: pageContent.textChunk1, isFirst: isFirstPage, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                        .padding(.horizontal, isCompact ? 20 : 35)
                                        .padding(.top, isCompact ? 10 : 15)
                                        
                                    HStack(alignment: .top, spacing: 15) {
                                        if let chunk2 = pageContent.textChunk2 {
                                            editorialText(chunk: chunk2, isFirst: false, textFont: textFont, dropCapFont: dropCapFont, textColor: textColors, dropCapColor: dropCapColor, lineSpacing: lineSpacing)
                                        }
                                        if let imgName = pageContent.imageName {
                                            Image(imgName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: isCompact ? 110 : 180, height: isCompact ? 110 : 180)
                                                .mask(
                                                    OrganicBlobMask()
                                                        .padding(5)
                                                        .blur(radius: 8)
                                                )
                                                .accessibilityHidden(true)
                                        }
                                    }
                                    .padding(.horizontal, isCompact ? 20 : 35)
                                    .padding(.bottom, isCompact ? 10 : 15)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding(.vertical, isCompact ? 10 : 20)
                        .overlay(
                            Group {
                                if isLocked {
                                    ZStack {
                                        Color.white.opacity(0.85) // Sbianca e nasconde leggermente i contenuti
                                            .edgesIgnoringSafeArea(.all)
                                            .blur(radius: 10)
                                        VStack {
                                            Image(systemName: "lock.fill")
                                                .font(.system(isCompact ? .title : .largeTitle))
                                                .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.1))
                                                .shadow(color: .white, radius: 4)
                                                .accessibilityHidden(true)
                                            Text(lm.t("Gioca per sbloccare le scene!"))
                                                .font(isDyslexiaEnabled ?
                                                      (isCompact ? Font.app(.headline, weight: .bold) : Font.app(.title, weight: .bold)) :
                                                        Font.custom("Alegreya", size: isCompact ? 20 : 30, relativeTo: .title))
                                                .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.1))
                                                .multilineTextAlignment(.center)
                                                .padding(.top, 10)
                                        }
                                    }
                                }
                            }
                        )
                    }
                    newPages.append(page)
                    var textToSpeak = pageContent.textChunk1
                    if let chunk2 = pageContent.textChunk2 {
                        textToSpeak += " " + chunk2
                    }
                    newPageTexts.append(isLocked ? "" : textToSpeak)
                    pageIndex += 1
                }
            }
        }

        let finalPageNumber = newPages.count + 1
        let isLeft = newPages.count % 2 == 0
        let finalIsLocked = finalPageNumber > maxUnlockedPage
        let finalImagePage = pageContainer(isLeft: isLeft, pageNumber: finalPageNumber, showVines: true) {
            GeometryReader { geo in
                ZStack {
                    Image("FinalImage")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .mask(
                            Rectangle()
                                .fill(Color.black)
                                .padding(isCompact ? 20 : 40)
                                .blur(radius: isCompact ? 30 : 60)
                        )
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    
                    if finalIsLocked {
                        ZStack {
                            Color.white.opacity(0.85)
                                .edgesIgnoringSafeArea(.all)
                                .blur(radius: 10)
                            VStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(isCompact ? .title : .largeTitle))
                                    .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.1))
                                    .accessibilityHidden(true)
                                Text(lm.t("Gioca per sbloccare le scene!"))
                                    .font(isDyslexiaEnabled ?
                                          (isCompact ? Font.app(.headline, weight: .bold) : Font.app(.title, weight: .bold)) :
                                            Font.custom("Alegreya", size: isCompact ? 20 : 30, relativeTo: .title))
                                    .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.1))
                                    .padding(.top, 10)
                            }
                        }
                    }
                }
            }
            .padding(-pagePadding) // Annulla il padding per occupare tutta la pagina e sovrapporsi alla cornice
        }
        newPages.append(finalImagePage)
        newPageTexts.append("")
        
        if newPages.count % 2 != 0 {
            let emptyPage = pageContainer(isLeft: false, pageNumber: newPages.count + 1) {
                Spacer()
            }
            newPages.append(emptyPage)
            newPageTexts.append("")
        }

        self.bookPages = newPages
        self.bookmarks = newBookmarks
        self.pageTexts = newPageTexts
        speakCurrentPage()
    }

    private func speakCurrentPage() {
        guard currentPage >= 0, currentPage < pageTexts.count else { return }
        let text = pageTexts[currentPage]
        AppSpeechSynthesizer.shared.speak(text, languageCode: lm.currentLanguage)
    }
    
    @ViewBuilder
    private func editorialText(chunk: String, isFirst: Bool, textFont: Font, dropCapFont: Font, textColor: Color, dropCapColor: Color, lineSpacing: CGFloat, alignment: TextAlignment = .leading) -> some View {
        VStack(alignment: alignment == .center ? .center : (alignment == .trailing ? .trailing : .leading)) {
            if isFirst && !chunk.isEmpty {
                let firstChar = String(chunk.prefix(1))
                let restOfString = String(chunk.dropFirst())
                Text("\(Text(firstChar).font(dropCapFont).foregroundColor(dropCapColor))\(Text(restOfString).font(textFont).foregroundColor(textColor))")
                .lineSpacing(lineSpacing + 4)
                .multilineTextAlignment(alignment)
            } else if !chunk.isEmpty {
                Text(chunk)
                    .font(textFont)
                    .foregroundColor(textColor)
                    .lineSpacing(lineSpacing + 4)
                    .multilineTextAlignment(alignment)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : (alignment == .trailing ? .trailing : .leading))
    }
    
    @ViewBuilder
    private func editorialImage(imgName: String, height: CGFloat, removeBlur: Bool = false, offsetY: CGFloat = 0) -> some View {
        HStack {
            Spacer()
            Image(imgName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .offset(y: offsetY)
                .frame(width: height * 1.5, height: height)
                .mask(
                    OrganicBlobMask()
                        .padding(10)
                        .blur(radius: removeBlur ? 0 : 15)
                )
                .accessibilityHidden(true)
            Spacer()
        }
    }
}

struct OpenBookBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let pw = w / 2
            
            ZStack {
                // Leather Cover (Blue exterior)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color(red: 0.1, green: 0.25, blue: 0.5), Color(red: 0.05, green: 0.15, blue: 0.35)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: w + 40, height: h + 40)
                    .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 15)
                
                // Inner Cover Lining (Blue interior)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.15, green: 0.3, blue: 0.55))
                    .frame(width: w + 20, height: h + 20)
                
                // Left Page Stack
                ForEach(1...6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(red: 0.85, green: 0.8, blue: 0.65))
                        .frame(width: pw, height: h)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                        )
                        .offset(x: -pw / 2 - CGFloat(i * 2), y: CGFloat(i * 2))
                }
                
                // Right Page Stack
                ForEach(1...6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(red: 0.85, green: 0.8, blue: 0.65))
                        .frame(width: pw, height: h)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                        )
                        .offset(x: pw / 2 + CGFloat(i * 2), y: CGFloat(i * 2))
                }
                
                // Spine center shadow for depth
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8), .clear]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: 30, height: h + 40)
                    .offset(y: 5)
            }
            .position(x: w / 2, y: h / 2)
        }
    }
}

struct OrganicBlobMask: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.05, y: h * 0.1))
        path.addCurve(to: CGPoint(x: w * 0.95, y: h * 0.08),
                      control1: CGPoint(x: w * 0.4, y: h * -0.05),
                      control2: CGPoint(x: w * 0.6, y: h * 0.02))
        path.addCurve(to: CGPoint(x: w * 0.92, y: h * 0.92),
                      control1: CGPoint(x: w * 1.05, y: h * 0.4),
                      control2: CGPoint(x: w * 0.98, y: h * 0.7))
        path.addCurve(to: CGPoint(x: w * 0.08, y: h * 0.95),
                      control1: CGPoint(x: w * 0.7, y: h * 1.05),
                      control2: CGPoint(x: w * 0.3, y: h * 0.9))
        path.addCurve(to: CGPoint(x: w * 0.05, y: h * 0.1),
                      control1: CGPoint(x: w * -0.05, y: h * 0.6),
                      control2: CGPoint(x: w * 0.02, y: h * 0.3))
        
        return path
    }
}

struct FairyTaleFrame: View {
    let isLeft: Bool
    let pageNumber: Int
    var showVines: Bool = false
    
    var body: some View {
        GeometryReader { geom in
            let w = geom.size.width
            let h = geom.size.height
            let cornerRadius: CGFloat = 20
            let inset: CGFloat = 12
            
            ZStack {
                // Outer gold line
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color(red: 0.75, green: 0.65, blue: 0.4), lineWidth: 2)
                    .padding(inset)
                
                // Inner gold line
                RoundedRectangle(cornerRadius: cornerRadius - 4)
                    .stroke(Color(red: 0.75, green: 0.65, blue: 0.4), lineWidth: 1)
                    .padding(inset + 4)
                    
                if showVines {
                    TangledVines(inset: inset, cornerRadius: cornerRadius)
                }
                
                // Corner ornaments
                let ornamentColor = Color(red: 0.75, green: 0.65, blue: 0.4)
                
                // Top Left
                Image(systemName: "leaf.fill")
                    .foregroundColor(ornamentColor)
                    .font(.system(size: 16))
                    .rotationEffect(.degrees(135))
                    .position(x: inset + 8, y: inset + 8)
                
                // Top Right
                Image(systemName: "leaf.fill")
                    .foregroundColor(ornamentColor)
                    .font(.system(size: 16))
                    .rotationEffect(.degrees(-135))
                    .position(x: w - inset - 8, y: inset + 8)
                
                // Bottom Left
                Image(systemName: "leaf.fill")
                    .foregroundColor(ornamentColor)
                    .font(.system(size: 16))
                    .rotationEffect(.degrees(45))
                    .position(x: inset + 8, y: h - inset - 8)
                
                // Bottom Right
                Image(systemName: "leaf.fill")
                    .foregroundColor(ornamentColor)
                    .font(.system(size: 16))
                    .rotationEffect(.degrees(-45))
                    .position(x: w - inset - 8, y: h - inset - 8)
                    
                // Climbing Vine decoration varying per page
                ClimbingVine(pageNumber: pageNumber, w: w, h: h, inset: inset)
            }
            .accessibilityHidden(true)
            // Mask the side near the spine to make it look like a real page
            .padding(.trailing, isLeft ? -20 : 0)
            .padding(.leading, !isLeft ? -20 : 0)
            .clipped()
        }
    }
}

struct ClimbingVine: View {
    let pageNumber: Int
    let w: CGFloat
    let h: CGFloat
    let inset: CGFloat
    
    var body: some View {
        ZStack {
            let vineColor = Color(red: 0.75, green: 0.65, blue: 0.4) // Same as frame
            
            // Left edge, climbing from bottom to top
            if (pageNumber * 5) % 2 == 0 || pageNumber % 4 == 1 {
                Path { p in
                    p.move(to: CGPoint(x: inset, y: h - inset)) // Start at bottom left
                    for i in 1...7 {
                        let stepY = (h - 2 * inset) / 7
                        let y = (h - inset) - stepY * CGFloat(i)
                        let prevY = (h - inset) - stepY * CGFloat(i - 1)
                        let midY = (y + prevY) / 2
                        let offset: CGFloat = i % 2 == 0 ? 10 : -10
                        p.addQuadCurve(to: CGPoint(x: inset, y: y), control: CGPoint(x: inset + offset, y: midY))
                    }
                }
                .stroke(vineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                
                ForEach(0..<7, id: \.self) { i in
                    let stepY = (h - 2 * inset) / 7
                    let yPos = (h - inset) - stepY * CGFloat(i) - stepY / 2
                    Image(systemName: "leaf.fill")
                        .foregroundColor(vineColor)
                        .font(.system(size: 16))
                        .rotationEffect(.degrees(i % 2 == 0 ? -30 : 30))
                        .position(x: inset + (i % 2 == 0 ? 8 : -8), y: yPos)
                }
            }
            
            // Right edge, climbing from bottom to top
            if (pageNumber * 11) % 2 == 0 || pageNumber % 4 == 3 {
                Path { p in
                    p.move(to: CGPoint(x: w - inset, y: h - inset)) // Start at bottom right
                    for i in 1...7 {
                        let stepY = (h - 2 * inset) / 7
                        let y = (h - inset) - stepY * CGFloat(i)
                        let prevY = (h - inset) - stepY * CGFloat(i - 1)
                        let midY = (y + prevY) / 2
                        let offset: CGFloat = i % 2 == 0 ? 10 : -10
                        p.addQuadCurve(to: CGPoint(x: w - inset, y: y), control: CGPoint(x: w - inset + offset, y: midY))
                    }
                }
                .stroke(vineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                
                ForEach(0..<7, id: \.self) { i in
                    let stepY = (h - 2 * inset) / 7
                    let yPos = (h - inset) - stepY * CGFloat(i) - stepY / 2
                    Image(systemName: "leaf.fill")
                        .foregroundColor(vineColor)
                        .font(.system(size: 16))
                        .rotationEffect(.degrees(i % 2 == 0 ? -30 : 30))
                        .position(x: w - inset + (i % 2 == 0 ? -8 : 8), y: yPos)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct PageBackgroundDecal: View {
    let pageNumber: Int
    
    var body: some View {
        GeometryReader { geom in
            let w = geom.size.width
            let h = geom.size.height
            let decalColor = Color(red: 0.75, green: 0.65, blue: 0.4).opacity(0.15)
            
            ZStack {
                let seed = pageNumber % 6
                if seed == 0 {
                    // Branch from top right
                    Path { p in
                        p.move(to: CGPoint(x: w, y: h * 0.1))
                        p.addQuadCurve(to: CGPoint(x: w * 0.6, y: h * 0.3), control: CGPoint(x: w * 0.9, y: h * 0.3))
                        p.move(to: CGPoint(x: w * 0.8, y: h * 0.22))
                        p.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.15), control: CGPoint(x: w * 0.75, y: h * 0.18))
                    }
                    .stroke(decalColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    
                    Image(systemName: "leaf.fill")
                        .foregroundColor(decalColor)
                        .font(.system(size: 40))
                        .rotationEffect(.degrees(45))
                        .position(x: w * 0.6, y: h * 0.3)
                } else if seed == 1 {
                    // Branch from bottom left
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * 0.8))
                        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.6), control: CGPoint(x: w * 0.2, y: h * 0.6))
                        p.move(to: CGPoint(x: w * 0.2, y: h * 0.68))
                        p.addQuadCurve(to: CGPoint(x: w * 0.4, y: h * 0.75), control: CGPoint(x: w * 0.3, y: h * 0.75))
                    }
                    .stroke(decalColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    
                    Image(systemName: "leaf.fill")
                        .foregroundColor(decalColor)
                        .font(.system(size: 45))
                        .rotationEffect(.degrees(135))
                        .position(x: w * 0.5, y: h * 0.6)
                } else if seed == 2 {
                    // Branch from top left
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * 0.2))
                        p.addQuadCurve(to: CGPoint(x: w * 0.4, y: h * 0.4), control: CGPoint(x: w * 0.1, y: h * 0.4))
                    }
                    .stroke(decalColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    
                    Image(systemName: "leaf.fill")
                        .foregroundColor(decalColor)
                        .font(.system(size: 35))
                        .rotationEffect(.degrees(-45))
                        .position(x: w * 0.4, y: h * 0.4)
                } else if seed == 3 {
                    // Tree silhouette bottom right
                    Path { p in
                        p.move(to: CGPoint(x: w * 0.8, y: h))
                        p.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.75), control: CGPoint(x: w * 0.75, y: h * 0.85))
                        p.move(to: CGPoint(x: w * 0.85, y: h * 0.8))
                        p.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.65), control: CGPoint(x: w * 0.8, y: h * 0.7))
                        p.move(to: CGPoint(x: w * 0.85, y: h * 0.75))
                        p.addQuadCurve(to: CGPoint(x: w * 0.95, y: h * 0.6), control: CGPoint(x: w * 0.9, y: h * 0.7))
                    }
                    .stroke(decalColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    
                    Image(systemName: "leaf.fill")
                        .foregroundColor(decalColor)
                        .font(.system(size: 35))
                        .rotationEffect(.degrees(15))
                        .position(x: w * 0.7, y: h * 0.65)
                    Image(systemName: "leaf.fill")
                        .foregroundColor(decalColor)
                        .font(.system(size: 40))
                        .rotationEffect(.degrees(-20))
                        .position(x: w * 0.95, y: h * 0.6)
                    Image(systemName: "leaf.fill")
                        .foregroundColor(decalColor)
                        .font(.system(size: 45))
                        .rotationEffect(.degrees(-5))
                        .position(x: w * 0.85, y: h * 0.75)
                } else if seed == 4 {
                    // Flowers on bottom center/left
                    Path { p in
                        p.move(to: CGPoint(x: w * 0.3, y: h))
                        p.addQuadCurve(to: CGPoint(x: w * 0.25, y: h * 0.85), control: CGPoint(x: w * 0.2, y: h * 0.95))
                        p.move(to: CGPoint(x: w * 0.35, y: h))
                        p.addQuadCurve(to: CGPoint(x: w * 0.45, y: h * 0.8), control: CGPoint(x: w * 0.45, y: h * 0.9))
                    }
                    .stroke(decalColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    Image(systemName: "rosette")
                        .foregroundColor(decalColor)
                        .font(.system(size: 30))
                        .position(x: w * 0.25, y: h * 0.85)
                    Image(systemName: "rosette")
                        .foregroundColor(decalColor)
                        .font(.system(size: 40))
                        .position(x: w * 0.45, y: h * 0.8)
                } else if seed == 5 {
                    // Wildflowers on top center
                    Path { p in
                        p.move(to: CGPoint(x: w * 0.5, y: 0))
                        p.addQuadCurve(to: CGPoint(x: w * 0.6, y: h * 0.15), control: CGPoint(x: w * 0.5, y: h * 0.1))
                        p.move(to: CGPoint(x: w * 0.4, y: 0))
                        p.addQuadCurve(to: CGPoint(x: w * 0.3, y: h * 0.1), control: CGPoint(x: w * 0.4, y: h * 0.05))
                    }
                    .stroke(decalColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    Image(systemName: "rosette")
                        .foregroundColor(decalColor)
                        .font(.system(size: 25))
                        .position(x: w * 0.6, y: h * 0.15)
                    Image(systemName: "rosette")
                        .foregroundColor(decalColor)
                        .font(.system(size: 30))
                        .position(x: w * 0.3, y: h * 0.1)
                }
            }
            .accessibilityHidden(true)
        }
    }
}

struct TangledVines: View {
    let inset: CGFloat
    let cornerRadius: CGFloat
    let vineColor = Color(red: 0.18, green: 0.40, blue: 0.15) // Deep organic green
    let flowerColor = Color(red: 0.8, green: 0.2, blue: 0.3) // Soft red/pink
    
    var body: some View {
        GeometryReader { geom in
            let w = geom.size.width - inset * 2
            let h = geom.size.height - inset * 2
            
            ZStack {
                // Tralci (linee intrecciate)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(vineColor.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [10, 8]))
                    .rotationEffect(.degrees(0.3))
                    .padding(inset)
                
                RoundedRectangle(cornerRadius: cornerRadius + 2)
                    .stroke(vineColor.opacity(0.6), style: StrokeStyle(lineWidth: 1.0, dash: [6, 12]))
                    .rotationEffect(.degrees(-0.4))
                    .padding(inset - 2)
                    
                RoundedRectangle(cornerRadius: cornerRadius - 2)
                    .stroke(vineColor.opacity(0.9), style: StrokeStyle(lineWidth: 2.0, dash: [15, 10]))
                    .scaleEffect(1.005)
                    .padding(inset + 2)
                
                // Foglie sparse
                ForEach(0..<45, id: \.self) { i in
                    let progress = Double(i) / 45.0
                    let pos = pointOnRect(progress: progress, w: w, h: h)
                    let rotation = Angle.degrees(Double.random(in: 0...360))
                    let size = CGFloat.random(in: 8...16)
                    
                    Image(systemName: "leaf.fill")
                        .foregroundColor(vineColor.opacity(Double.random(in: 0.7...1.0)))
                        .font(.system(size: size))
                        .rotationEffect(rotation)
                        .position(x: pos.x + inset, y: pos.y + inset)
                        .offset(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -8...8))
                }
                
                // Fiori / Bacche incantate
                ForEach(0..<12, id: \.self) { i in
                    let progress = (Double(i) / 12.0) + 0.04
                    let pos = pointOnRect(progress: progress.truncatingRemainder(dividingBy: 1.0), w: w, h: h)
                    
                    Circle()
                        .fill(flowerColor)
                        .frame(width: 5, height: 5)
                        .position(x: pos.x + inset, y: pos.y + inset)
                        .offset(x: CGFloat.random(in: -6...6), y: CGFloat.random(in: -6...6))
                }
            }
        }
    }
    
    func pointOnRect(progress: Double, w: CGFloat, h: CGFloat) -> CGPoint {
        let perimeter = 2 * w + 2 * h
        let distance = progress * perimeter
        if distance < w {
            return CGPoint(x: distance, y: 0)
        } else if distance < w + h {
            return CGPoint(x: w, y: distance - w)
        } else if distance < 2 * w + h {
            return CGPoint(x: w - (distance - (w + h)), y: h)
        } else {
            return CGPoint(x: 0, y: h - (distance - (2 * w + h)))
        }
    }
}
