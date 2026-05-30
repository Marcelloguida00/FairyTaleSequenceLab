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
    let emoji: String
}

struct FairyTaleBookmark: Identifiable {
    let id = UUID()
    let info: FairyTaleInfo
    let startPageIndex: Int
}

struct StoryScene: Identifiable {
    let id: Int
    let titleKey: String
    let text1Key: String
    let text2Key: String
    let introImageName: String
    let rewardImageName: String
}

struct BookView: View {
    static let redHoodScenes = [
        StoryScene(
            id: 1,
            titleKey: "story.redhood.scene1.title",
            text1Key: "story.redhood.scene1.text1",
            text2Key: "story.redhood.scene1.text2",
            introImageName: "Introduzione 1 evento",
            rewardImageName: "Fine primo evento"
        ),
        StoryScene(
            id: 2,
            titleKey: "story.redhood.scene2.title",
            text1Key: "story.redhood.scene2.text1",
            text2Key: "story.redhood.scene2.text2",
            introImageName: "Introduzione 2 evento",
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
                                    
                                    Text(bookmark.info.emoji)
                                        .font(.system(size: isCompact ? 12 : 20))
                                        .offset(y: isCompact ? -3 : -5)
                                }
                            }
                            .buttonStyle(.plain)
                            .offset(x: isBookmarkActive(bookmark) ? (isCompact ? -12 : -20) : 0)
                            .animation(.spring(), value: currentPage)
                        }
                    }
                    .offset(x: isCompact ? 15 : 30, y: isCompact ? 10 : 20)
                }
                .aspectRatio(1.5, contentMode: .fit)
                .padding(isCompact ? 12 : 50)
                
                // Close Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: isCompact ? 30 : 40))
                                .foregroundColor(.white)
                                .padding(isCompact ? 12 : 20)
                        }
                    }
                    Spacer()
                }
            }
            .onAppear {
                let initialCompact = geom.size.width < 600
                self.lastIsCompact = initialCompact
                loadCompletedEvents(isCompact: initialCompact)
            }
            .onChange(of: lm.currentLanguage) { _ in
                if let isCompact = lastIsCompact {
                    buildPagesAndBookmarks(isCompact: isCompact)
                }
            }
            .onChange(of: geom.size.width) { _ in
                let isCompact = geom.size.width < 600
                if isCompact != lastIsCompact {
                    self.lastIsCompact = isCompact
                    buildPagesAndBookmarks(isCompact: isCompact)
                }
            }
        }
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
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let maxChars = isCompact 
            ? (isDyslexiaEnabled ? 130 : 180) 
            : (isDyslexiaEnabled ? 180 : 250)
            
        var pages: [String] = []
        var currentPage = ""
        
        for paragraph in paragraphs {
            if currentPage.isEmpty {
                currentPage = paragraph
            } else {
                if currentPage.count + paragraph.count + 2 > maxChars {
                    pages.append(currentPage)
                    currentPage = paragraph
                } else {
                    currentPage += "\n\n" + paragraph
                }
            }
        }
        
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }
        
        return pages
    }
    
    private func buildPagesAndBookmarks(isCompact: Bool) {
        var newPages: [AnyView] = []
        var newBookmarks: [FairyTaleBookmark] = []
        
        let isDyslexiaEnabled = UserDefaults.standard.bool(forKey: AppFontSettings.dyslexiaFontKey)
        let pagePadding: CGFloat = isCompact ? 16 : 40
        let titleFont = isCompact ? Font.app(.headline, weight: .bold) : Font.app(.title, weight: .bold)
        let textFont = isCompact ? Font.app(.subheadline, weight: .regular) : Font.app(.title3, weight: .regular)
        let lineSpacing: CGFloat = isCompact ? 3 : 6
        
        func pageContainer<Content: View>(isLeft: Bool, @ViewBuilder content: () -> Content) -> AnyView {
            AnyView(
                ZStack {
                    Color(red: 0.96, green: 0.92, blue: 0.82)
                    
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
                    
                    content()
                        .padding(pagePadding)
                }
                .clipped()
            )
        }
        
        func addPlaceholder(title: String, subtitle: String) {
            let emptyLeft = pageContainer(isLeft: true) {
                VStack(spacing: isCompact ? 10 : 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: isCompact ? 30 : 60))
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                    Text(subtitle)
                        .font(isCompact ? .app(.subheadline) : .app(.title3))
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                        .multilineTextAlignment(.center)
                }
            }
            let emptyRight = pageContainer(isLeft: false) {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(isCompact ? .app(.headline) : .app(.title))
                        .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.1))
                    Spacer()
                }
            }
            newPages.append(emptyLeft)
            newPages.append(emptyRight)
        }
        
        let redRidingHood = FairyTaleInfo(
            title: lm.t("map.region.red_riding_hood"),
            color: Color(red: 0.7, green: 0.1, blue: 0.1),
            emoji: "👧"
        )

        newBookmarks.append(FairyTaleBookmark(info: redRidingHood, startPageIndex: 0))

        if completedEvents.isEmpty {
            addPlaceholder(title: redRidingHood.title, subtitle: lm.t("Gioca per sbloccare le scene!"))
        } else {
            let maxCompletedId = completedEvents.map(\.id).max() ?? 0
            let visibleScenes = Array(BookView.redHoodScenes.prefix(maxCompletedId))

            if visibleScenes.isEmpty {
                addPlaceholder(title: redRidingHood.title, subtitle: lm.t("Gioca per sbloccare le scene!"))
            } else {
                var pageIndex = newPages.count
                for scene in visibleScenes {
                    // Page 1: Chapter Title + Intro Image
                    let introPage = pageContainer(isLeft: pageIndex % 2 == 0) {
                        VStack(spacing: isCompact ? 10 : 20) {
                            Text(lm.t(scene.titleKey))
                                .font(titleFont)
                                .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.1))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, isCompact ? 10 : 20)

                            Rectangle()
                                .fill(Color(red: 0.55, green: 0.31, blue: 0.09).opacity(0.3))
                                .frame(height: 1.5)
                                .frame(width: isCompact ? 40 : 80)

                            Spacer(minLength: 0)

                            if UIImage(named: scene.introImageName) != nil {
                                Image(scene.introImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(isCompact ? 8 : 12)
                                    .shadow(color: .black.opacity(0.15), radius: isCompact ? 3 : 6, x: 0, y: isCompact ? 2 : 4)
                                    .padding(.horizontal, isCompact ? 10 : 20)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: isCompact ? 8 : 12)
                                        .fill(LinearGradient(
                                            colors: [Color(red: 0.98, green: 0.96, blue: 0.92), Color(red: 0.90, green: 0.85, blue: 0.75)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))

                                    RoundedRectangle(cornerRadius: isCompact ? 8 : 12)
                                        .strokeBorder(
                                            Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.5),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                        )

                                    VStack(spacing: isCompact ? 4 : 8) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: isCompact ? 20 : 32))
                                            .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.15))
                                        Text(lm.t("Immagine di Introduzione"))
                                            .font(.app(isCompact ? .caption : .subheadline, weight: .bold))
                                            .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.1))
                                    }
                                }
                                .aspectRatio(16/9, contentMode: .fit)
                                .padding(.horizontal, isCompact ? 10 : 20)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, isCompact ? 12 : 30)
                    }
                    newPages.append(introPage)
                    pageIndex += 1

                    // Text Pages
                    let fullText = lm.t(scene.text1Key) + "\n\n" + lm.t(scene.text2Key)
                    let textPages = paginateText(fullText, isDyslexiaEnabled: isDyslexiaEnabled, isCompact: isCompact)

                    for chunk in textPages {
                        let textPage = pageContainer(isLeft: pageIndex % 2 == 0) {
                            VStack(alignment: .leading, spacing: isCompact ? 8 : 16) {
                                Text(chunk)
                                    .font(textFont)
                                    .foregroundColor(Color(red: 0.2, green: 0.1, blue: 0.05))
                                    .lineSpacing(lineSpacing)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, isCompact ? 5 : 10)
                            }
                            .padding(.vertical, isCompact ? 10 : 20)
                        }
                        newPages.append(textPage)
                        pageIndex += 1
                    }

                    // Filler Page (if total scene pages is odd, we balance to keep it double-sided)
                    if textPages.count % 2 != 0 {
                        let fillerPage = pageContainer(isLeft: pageIndex % 2 == 0) {
                            VStack {
                                Spacer()
                                Text("🌸")
                                    .font(.system(size: isCompact ? 18 : 30))
                                    .opacity(0.3)
                                Spacer()
                            }
                        }
                        newPages.append(fillerPage)
                        pageIndex += 1
                    }

                    // Reward Image Page
                    let rewardPage = pageContainer(isLeft: pageIndex % 2 == 0) {
                        VStack {
                            Spacer()
                            if UIImage(named: scene.rewardImageName) != nil {
                                Image(scene.rewardImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(isCompact ? 8 : 12)
                                    .shadow(color: .black.opacity(0.15), radius: isCompact ? 3 : 6, x: 0, y: isCompact ? 2 : 4)
                                    .padding(.horizontal, isCompact ? 10 : 20)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: isCompact ? 8 : 12)
                                        .fill(LinearGradient(
                                            colors: [Color(red: 0.98, green: 0.96, blue: 0.92), Color(red: 0.90, green: 0.85, blue: 0.75)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))

                                    RoundedRectangle(cornerRadius: isCompact ? 8 : 12)
                                        .strokeBorder(
                                            Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.5),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                        )

                                    VStack(spacing: isCompact ? 4 : 8) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: isCompact ? 20 : 32))
                                            .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.15))
                                        Text(lm.t("Immagine di Ricompensa"))
                                            .font(.app(isCompact ? .caption : .subheadline, weight: .bold))
                                            .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.1))
                                    }
                                }
                                .aspectRatio(16/9, contentMode: .fit)
                                .padding(.horizontal, isCompact ? 10 : 20)
                            }
                            Spacer()
                        }
                        .padding(.vertical, isCompact ? 12 : 30)
                    }
                    newPages.append(rewardPage)
                    pageIndex += 1
                }
            }
        }

        self.bookPages = newPages
        self.bookmarks = newBookmarks
    }
}

private struct OpenBookBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let pw = w / 2
            
            ZStack {
                // Leather Cover
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color(red: 0.25, green: 0.12, blue: 0.08), Color(red: 0.15, green: 0.06, blue: 0.04)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: w + 40, height: h + 40)
                    .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 15)
                
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
