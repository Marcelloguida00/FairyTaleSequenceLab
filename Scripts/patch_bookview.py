import re

swift_code = """
        func pageContainer<Content: View>(isLeft: Bool, pageNumber: Int? = nil, @ViewBuilder content: @escaping () -> Content) -> AnyView {
            AnyView(
                GeometryReader { geom in
                    ZStack {
                        // Warmer, lighter cream color for classic book pages
                        Color(red: 0.98, green: 0.96, blue: 0.90)
                        
                        // Forest image visible only at the outer corners
                        Image("FairyTaleBackground")
                            .resizable()
                            .scaledToFill()
                            .mask {
                                GeometryReader { maskGeom in
                                    let w = maskGeom.size.width
                                    let h = maskGeom.size.height
                                    let size: CGFloat = isCompact ? 250 : 400
                                    
                                    ZStack {
                                        // Top outer corner
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: size, height: size)
                                            .position(x: isLeft ? 0 : w, y: 0)
                                        
                                        // Bottom outer corner
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: size, height: size)
                                            .position(x: isLeft ? 0 : w, y: h)
                                    }
                                    .blur(radius: isCompact ? 40 : 70)
                                }
                            }
                            .clipped()
                        
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
                            .frame(width: geom.size.width, height: geom.size.height, alignment: .center)
                    }
                    .clipped()
                }
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
            let maxCompletedId = completedEvents.map(\\.id).max() ?? 0
            let visibleScenes = Array(BookView.redHoodScenes.prefix(maxCompletedId))

            if visibleScenes.isEmpty {
                addPlaceholder(title: redRidingHood.title, subtitle: lm.t("Gioca per sbloccare le scene!"))
            } else {
                var allWords: [String] = []
                var allCardImages: [String] = []
                
                for scene in visibleScenes {
                    let introImg = scene.introImageName
                    if !introImg.isEmpty { allCardImages.append(introImg) }
                    let fullText = lm.t(scene.text1Key) + " " + lm.t(scene.text2Key)
                    let words = fullText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    allWords.append(contentsOf: words)
                    let rewardImg = scene.rewardImageName
                    if !rewardImg.isEmpty { allCardImages.append(rewardImg) }
                }
                
                let wordsPerImage = allCardImages.isEmpty ? allWords.count + 1 : max(1, allWords.count / allCardImages.count)
                
                var allElements: [StoryElement] = []
                var currentTextChunk = ""
                var isFirstCharOfBook = true
                var imageIndex = 0
                var wordCounter = 0
                
                for word in allWords {
                    if wordCounter > 0 && wordCounter % wordsPerImage == 0 && imageIndex < allCardImages.count {
                        if !currentTextChunk.isEmpty {
                            let imgName = allCardImages[imageIndex]
                            allElements.append(.row(imageName: imgName, text: currentTextChunk.trimmingCharacters(in: .whitespaces), isFirstChar: isFirstCharOfBook, imageOnLeft: false, height: isCompact ? 150 : 250))
                            isFirstCharOfBook = false
                            currentTextChunk = ""
                            imageIndex += 1
                        }
                    }
                    currentTextChunk += word + " "
                    wordCounter += 1
                }
                
                if !currentTextChunk.isEmpty {
                    allElements.append(.row(imageName: nil, text: currentTextChunk.trimmingCharacters(in: .whitespaces), isFirstChar: isFirstCharOfBook, imageOnLeft: false, height: 0))
                }
                
                while imageIndex < allCardImages.count {
                    allElements.append(.row(imageName: allCardImages[imageIndex], text: "", isFirstChar: false, imageOnLeft: false, height: isCompact ? 150 : 250))
                    imageIndex += 1
                }
                
                var allPagesElements: [[StoryElement]] = []
                var currentPageElements: [StoryElement] = []
                var currentCost: CGFloat = 0
                let maxCost: CGFloat = isCompact ? 500 : 800
                
                for element in allElements {
                    var elementCost: CGFloat = 0
                    if case .row(let img, let text, _, _, let h) = element {
                        if img != nil { elementCost += h }
                        if !text.isEmpty { elementCost += CGFloat(text.count) * (isCompact ? 0.6 : 0.4) }
                    }
                    
                    if currentCost + elementCost > maxCost && !currentPageElements.isEmpty {
                        allPagesElements.append(currentPageElements)
                        currentPageElements = []
                        currentCost = 0
                    }
                    
                    currentPageElements.append(element)
                    currentCost += elementCost
                }
                if !currentPageElements.isEmpty {
                    allPagesElements.append(currentPageElements)
                }
                
                var pageIndex = newPages.count
                let dropCapFont = isCompact ? Font.app(.largeTitle, weight: .bold) : Font.app(size: 60, weight: .bold)
                
                for elements in allPagesElements {
                    let page = pageContainer(isLeft: pageIndex % 2 == 0, pageNumber: pageIndex + 1) {
                        HStack(alignment: .top, spacing: isCompact ? 10 : 20) {
                            // Text Column
                            VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                                ForEach(0..<elements.count, id: \\.self) { i in
                                    if case .row(_, let textStr, let isFirst, _, _) = elements[i], !textStr.isEmpty {
                                        Group {
                                            if isFirst {
                                                let firstChar = String(textStr.prefix(1))
                                                let restOfString = String(textStr.dropFirst())
                                                (Text(firstChar)
                                                    .font(dropCapFont)
                                                    .foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))
                                                 + Text(restOfString)
                                                    .font(textFont)
                                                    .foregroundColor(Color(red: 0.2, green: 0.1, blue: 0.05)))
                                                .lineSpacing(lineSpacing)
                                            } else {
                                                Text(textStr)
                                                    .font(textFont)
                                                    .foregroundColor(Color(red: 0.2, green: 0.1, blue: 0.05))
                                                    .lineSpacing(lineSpacing)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Images Column
                            VStack(alignment: .center, spacing: isCompact ? 10 : 20) {
                                ForEach(0..<elements.count, id: \\.self) { i in
                                    if case .row(let imgName, _, _, let imgOnLeft, let h) = elements[i], let img = imgName, UIImage(named: img) != nil {
                                        Image(img)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: isCompact ? 120 : 180, maxHeight: h)
                                            .mask(
                                                OrganicBlobMask()
                                                    .scaleEffect(x: imgOnLeft ? 1 : -1, y: 1)
                                                    .padding(10)
                                                    .blur(radius: 15)
                                            )
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(width: isCompact ? 120 : 180)
                        }
                    }
                    newPages.append(page)
                    pageIndex += 1
                }
            }
        }

        self.bookPages = newPages
        self.bookmarks = newBookmarks
    }
}

struct OrganicBlobMask: View {
    var body: some View {
        OrganicBlobShape()
            .fill(Color.black)
    }
}

struct OrganicBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.4),
                      control1: CGPoint(x: w * 0.9, y: 0),
                      control2: CGPoint(x: w * 1.1, y: h * 0.1))
        path.addCurve(to: CGPoint(x: w * 0.6, y: h),
                      control1: CGPoint(x: w * 0.9, y: h * 0.8),
                      control2: CGPoint(x: w * 0.8, y: h * 1.05))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.6),
                      control1: CGPoint(x: w * 0.3, y: h * 0.95),
                      control2: CGPoint(x: -w * 0.1, y: h * 0.8))
        path.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                      control1: CGPoint(x: w * 0.1, y: h * 0.3),
                      control2: CGPoint(x: w * 0.1, y: 0))
        
        return path
    }
}
"""

with open("Final Version/SharedUI/BookView.swift", "r") as f:
    content = f.read()

# Replace everything from `func pageContainer` to the end of the file!
pattern = r"        func pageContainer<Content: View>\(isLeft: Bool, @ViewBuilder content: @escaping \(\) -> Content\) -> AnyView \{.*"
match = re.search(pattern, content, re.DOTALL)
if match:
    new_content = content[:match.start()] + swift_code.strip() + "\n"
    with open("Final Version/SharedUI/BookView.swift", "w") as f:
        f.write(new_content)
    print("Replaced successfully")
else:
    print("Pattern not found")
