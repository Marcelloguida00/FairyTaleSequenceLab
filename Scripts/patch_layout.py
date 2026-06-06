import re

with open("Final Version/SharedUI/BookView.swift", "r") as f:
    content = f.read()

# Define the new enums and logic inside buildPagesAndBookmarks
old_pagination_logic = r"                let allEvents = EventLoader\.all\(from: \.main\).*?var pageIndex = newPages\.count"

new_pagination_logic = """                let allEvents = EventLoader.all(from: .main)
                
                enum PageData {
                    case fullImage(String)
                    case textAndImage(text: String, title: String?, imageName: String?, isTopImage: Bool, isDropCap: Bool)
                    case textOnly(text: String, title: String?, isDropCap: Bool)
                }
                
                var pagesData: [PageData] = []
                var isFirstPageOfBook = true
                var imageAlternator = true
                
                for scene in visibleScenes {
                    var sceneImages: [String] = []
                    
                    if !scene.introImageName.isEmpty {
                        pagesData.append(.fullImage(scene.introImageName))
                    }
                    
                    if let ev = allEvents.first(where: { $0.id == scene.id }) {
                        let sortedCards = ev.cards.sorted { $0.correctPosition < $1.correctPosition }
                        if sortedCards.count > 0 { sceneImages.append(sortedCards[0].imageName) }
                        if sortedCards.count > 1 { sceneImages.append(sortedCards[1].imageName) }
                    }
                    if !scene.rewardImageName.isEmpty {
                        sceneImages.append(scene.rewardImageName)
                    }
                    
                    let fullText = lm.t(scene.text1Key) + "\\n\\n" + lm.t(scene.text2Key)
                    let words = fullText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    
                    var currentText = ""
                    var isFirstPageOfScene = true
                    var imageIndex = 0
                    
                    for word in words {
                        currentText += word + " "
                        let hasImage = imageIndex < sceneImages.count
                        let threshold = hasImage ? (isCompact ? 100 : 250) : (isCompact ? 250 : 550)
                        
                        if currentText.count > threshold {
                            let title = (isFirstPageOfScene && isFirstPageOfBook) ? redRidingHood.title : nil
                            if hasImage {
                                let img = sceneImages[imageIndex]
                                pagesData.append(.textAndImage(text: currentText.trimmingCharacters(in: .whitespaces), title: title, imageName: img, isTopImage: imageAlternator, isDropCap: isFirstPageOfBook))
                                imageIndex += 1
                                imageAlternator.toggle()
                            } else {
                                pagesData.append(.textOnly(text: currentText.trimmingCharacters(in: .whitespaces), title: title, isDropCap: isFirstPageOfBook))
                            }
                            currentText = ""
                            isFirstPageOfScene = false
                            isFirstPageOfBook = false
                        }
                    }
                    
                    if !currentText.isEmpty {
                        let title = (isFirstPageOfScene && isFirstPageOfBook) ? redRidingHood.title : nil
                        let hasImage = imageIndex < sceneImages.count
                        if hasImage {
                            pagesData.append(.textAndImage(text: currentText.trimmingCharacters(in: .whitespaces), title: title, imageName: sceneImages[imageIndex], isTopImage: imageAlternator, isDropCap: isFirstPageOfBook))
                            imageAlternator.toggle()
                        } else {
                            pagesData.append(.textOnly(text: currentText.trimmingCharacters(in: .whitespaces), title: title, isDropCap: isFirstPageOfBook))
                        }
                        isFirstPageOfBook = false
                    }
                }
                
                var pageIndex = newPages.count"""

content = re.sub(old_pagination_logic, new_pagination_logic, content, flags=re.DOTALL)


# Now patch the actual page rendering loop
old_render_loop = r"                let dropCapFont = isCompact \? Font\.app\(\.largeTitle, weight: \.bold\) : Font\.app\(size: 60, weight: \.bold\)\n                \n                for elements in allPagesElements \{.*?newPages\.append\(page\)\n                    pageIndex \+= 1\n                \}"

new_render_loop = """                let dropCapFont = isCompact ? Font.app(.largeTitle, weight: .bold) : Font.app(size: 80, weight: .bold)
                let titleDisplayFont = isCompact ? Font.app(.largeTitle, weight: .bold) : Font.app(size: 60, weight: .bold)
                
                let imageBlock: (String?, Bool) -> AnyView = { imgName, isLeft in
                    if let name = imgName, let img = UIImage(named: name) {
                        return AnyView(
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: isCompact ? 200 : 350)
                                .mask(
                                    OrganicBlobMask()
                                        .scaleEffect(x: isLeft ? 1 : -1, y: 1)
                                        .padding(10)
                                        .blur(radius: 20)
                                )
                                .clipped()
                                .padding(.vertical, isCompact ? 10 : 20)
                        )
                    }
                    return AnyView(EmptyView())
                }
                
                let textBlock: (String, String?, Bool) -> AnyView = { text, title, isDropCap in
                    AnyView(
                        VStack(alignment: .leading, spacing: isCompact ? 16 : 32) {
                            if let t = title {
                                Text(t)
                                    .font(titleDisplayFont)
                                    .foregroundColor(Color(red: 0.2, green: 0.1, blue: 0.05))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, isCompact ? 10 : 20)
                            }
                            
                            if isDropCap && !text.isEmpty {
                                let firstChar = String(text.prefix(1))
                                let restOfString = String(text.dropFirst())
                                (Text(firstChar)
                                    .font(dropCapFont)
                                    .foregroundColor(Color(red: 0.6, green: 0.1, blue: 0.1))
                                 + Text(restOfString)
                                    .font(textFont)
                                    .foregroundColor(Color(red: 0.2, green: 0.1, blue: 0.05)))
                                .lineSpacing(lineSpacing)
                            } else {
                                Text(text)
                                    .font(textFont)
                                    .foregroundColor(Color(red: 0.2, green: 0.1, blue: 0.05))
                                    .lineSpacing(lineSpacing)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    )
                }
                
                for pd in pagesData {
                    let isLeftPage = pageIndex % 2 == 0
                    let page = pageContainer(isLeft: isLeftPage, pageNumber: pageIndex + 1) {
                        switch pd {
                        case .fullImage(let imgName):
                            if let img = UIImage(named: imgName) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .mask(
                                        OrganicBlobMask()
                                            .padding(isCompact ? 10 : 20)
                                            .blur(radius: 20)
                                    )
                                    .clipped()
                            }
                        case .textAndImage(let text, let title, let imgName, let isTopImage, let isDropCap):
                            VStack(alignment: .leading, spacing: 0) {
                                if isTopImage {
                                    imageBlock(imgName, isLeftPage)
                                    textBlock(text, title, isDropCap)
                                } else {
                                    textBlock(text, title, isDropCap)
                                    Spacer(minLength: isCompact ? 16 : 24)
                                    imageBlock(imgName, isLeftPage)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, isCompact ? 24 : 48)
                            .padding(.top, isCompact ? 24 : 48)
                        case .textOnly(let text, let title, let isDropCap):
                            VStack(alignment: .leading, spacing: 0) {
                                textBlock(text, title, isDropCap)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, isCompact ? 24 : 48)
                            .padding(.top, isCompact ? 24 : 48)
                        }
                    }
                    newPages.append(page)
                    pageIndex += 1
                }"""

content = re.sub(old_render_loop, new_render_loop, content, flags=re.DOTALL)

with open("Final Version/SharedUI/BookView.swift", "w") as f:
    f.write(content)
