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
        // Update pages if they changed
        let pagesChanged = context.coordinator.parent.pages.count != pages.count
        if pagesChanged {
            context.coordinator.parent = self
            context.coordinator.setupControllers()
            
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
            self.setupControllers()
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
        
        func setupControllers() {
            controllers = parent.pages.enumerated().map { index, view in
                let hc = UIHostingController(rootView: view)
                hc.view.backgroundColor = .clear
                hc.view.tag = index
                return hc
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

let fairyTales = [
    FairyTaleInfo(title: "Cappuccetto Rosso", color: Color(red: 0.7, green: 0.1, blue: 0.1), emoji: "👧"), // Bimba/Cappuccetto
    FairyTaleInfo(title: "Biancaneve", color: Color(red: 0.1, green: 0.3, blue: 0.7), emoji: "💎"), // Gemma
    FairyTaleInfo(title: "La Bella e la Bestia", color: Color(red: 0.8, green: 0.6, blue: 0.1), emoji: "🌹"), // Rosa
    FairyTaleInfo(title: "Aladdin", color: Color(red: 0.5, green: 0.1, blue: 0.6), emoji: "🪔"), // Lampada
    FairyTaleInfo(title: "Il Principe Ranocchio", color: Color(red: 0.1, green: 0.6, blue: 0.2), emoji: "🐸") // Ranocchio
]

struct FairyTaleBookmark: Identifiable {
    let id = UUID()
    let info: FairyTaleInfo
    let startPageIndex: Int
}

struct BookView: View {
    let onDismiss: () -> Void
    @EnvironmentObject private var lm: LanguageManager
    @State private var completedEvents: [EventData] = []
    @State private var currentPage = 0
    @State private var bookPages: [AnyView] = []
    @State private var bookmarks: [FairyTaleBookmark] = []
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8).ignoresSafeArea()
            
            ZStack(alignment: .topTrailing) {
                OpenBookBackground()
                
                PageCurlBookView(pages: bookPages, currentPage: $currentPage)
                
                // Bookmarks UI
                VStack(spacing: 8) {
                    ForEach(bookmarks) { bookmark in
                        Button(action: {
                            // Turn to page when bookmark is tapped
                            currentPage = bookmark.startPageIndex
                        }) {
                            ZStack {
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: 40, y: 0))
                                    path.addLine(to: CGPoint(x: 40, y: 50))
                                    path.addLine(to: CGPoint(x: 20, y: 40))
                                    path.addLine(to: CGPoint(x: 0, y: 50))
                                    path.closeSubpath()
                                }
                                .fill(LinearGradient(gradient: Gradient(colors: [bookmark.info.color.opacity(0.9), bookmark.info.color.opacity(0.7)]), startPoint: .leading, endPoint: .trailing))
                                .frame(width: 40, height: 50)
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 2, y: 2)
                                
                                // Icon representing the specific fairy tale
                                Text(bookmark.info.emoji)
                                    .font(.system(size: 20))
                                    .offset(y: -5)
                            }
                        }
                        .buttonStyle(.plain)
                        // Make active bookmark stick out more
                        .offset(x: isBookmarkActive(bookmark) ? -20 : 0)
                        .animation(.spring(), value: currentPage)
                    }
                }
                .offset(x: 30, y: 20) // Hang off the right side
            }
            .aspectRatio(1.5, contentMode: .fit)
            .padding(50)
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            loadCompletedEvents()
        }
    }
    
    private func isBookmarkActive(_ bookmark: FairyTaleBookmark) -> Bool {
        // A bookmark is active if the current page is within its range
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return false }
        let startPage = bookmark.startPageIndex
        let endPage = (index < bookmarks.count - 1) ? bookmarks[index + 1].startPageIndex : bookPages.count
        return currentPage >= startPage && currentPage < endPage
    }
    
    private func loadCompletedEvents() {
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
        buildPagesAndBookmarks()
    }
    
    private func buildPagesAndBookmarks() {
        var newPages: [AnyView] = []
        var newBookmarks: [FairyTaleBookmark] = []
        
        func pageContainer<Content: View>(isLeft: Bool, @ViewBuilder content: () -> Content) -> AnyView {
            AnyView(
                ZStack {
                    // Solid page color
                    Color(red: 0.96, green: 0.92, blue: 0.82)
                    
                    // Spine shadow for depth
                    HStack(spacing: 0) {
                        if isLeft {
                            Spacer(minLength: 0)
                            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.4), .clear]), startPoint: .trailing, endPoint: .leading)
                                .frame(width: 40)
                        } else {
                            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.4), .clear]), startPoint: .leading, endPoint: .trailing)
                                .frame(width: 40)
                            Spacer(minLength: 0)
                        }
                    }
                    
                    content()
                        .padding(40)
                }
                .clipped()
            )
        }
        
        func addPlaceholder(title: String, subtitle: String) {
            let emptyLeft = pageContainer(isLeft: true) {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                    Text(subtitle)
                        .font(.app(.title3))
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                        .multilineTextAlignment(.center)
                }
            }
            let emptyRight = pageContainer(isLeft: false) {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.app(.title))
                        .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.1))
                    Spacer()
                }
            }
            newPages.append(emptyLeft)
            newPages.append(emptyRight)
        }
        
        // Build for each fairy tale
        for tale in fairyTales {
            let startPage = newPages.count
            newBookmarks.append(FairyTaleBookmark(info: tale, startPageIndex: startPage))
            
            if tale.title == "Cappuccetto Rosso" {
                if completedEvents.isEmpty {
                    addPlaceholder(title: tale.title, subtitle: "Gioca per sbloccare le scene!")
                } else {
                    for event in completedEvents {
                        let leftPage = pageContainer(isLeft: true) {
                            Image(event.rewardImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        let rightPage = pageContainer(isLeft: false) {
                            VStack(alignment: .leading, spacing: 20) {
                                Text(event.bannerTitle)
                                    .font(.app(.title))
                                    .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.1))
                                Text(event.rewardText)
                                    .font(.app(.title3))
                                    .foregroundColor(Color(red: 0.2, green: 0.1, blue: 0.05))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                        newPages.append(leftPage)
                        newPages.append(rightPage)
                    }
                }
            } else {
                addPlaceholder(title: tale.title, subtitle: "Prossimamente...")
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
