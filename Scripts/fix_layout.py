import re

with open("Final Version/SharedUI/BookView.swift", "r") as f:
    content = f.read()

# Fix 1: pageContainer
pattern_container = r"func pageContainer<Content: View>\(isLeft: Bool, pageNumber: Int\? = nil, @ViewBuilder content: @escaping \(\) -> Content\) -> AnyView \{.*?(?=func addPlaceholder)"
replacement_container = """func pageContainer<Content: View>(isLeft: Bool, pageNumber: Int? = nil, @ViewBuilder content: @escaping () -> Content) -> AnyView {
            AnyView(
                ZStack {
                    // Warmer, lighter cream color for classic book pages
                    Color(red: 0.98, green: 0.96, blue: 0.90)
                    
                    // Forest image visible only at the outer corners
                    Color.clear.overlay(
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
                    )
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            )
        }
        
        """
content = re.sub(pattern_container, replacement_container, content, flags=re.DOTALL)

# Fix 2: maxCost
content = content.replace("let maxCost: CGFloat = isCompact ? 500 : 800", "let maxCost: CGFloat = isCompact ? 350 : 550")

# Fix 3: Text fixedSize
pattern_text_group = r"Group \{\s*if isFirst \{.*?\}\s*\.frame\(maxWidth: \.infinity, alignment: \.leading\)"
replacement_text_group = """Group {
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
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)"""
content = re.sub(pattern_text_group, replacement_text_group, content, flags=re.DOTALL)

with open("Final Version/SharedUI/BookView.swift", "w") as f:
    f.write(content)
