with open("/Users/cirogiovannicalisto/Desktop/Progetti/CH7/Challenge-7-Apple-Accademy/Final Version/SharedUI/BookView.swift", "r") as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    # Insert new state var before body
    if "var body: some View {" in line and "BookView" in "".join(lines[max(0, i-20):i]):
        new_lines.append("    @State private var isBookOpen = false\n\n")
        new_lines.append("""
    @ViewBuilder
    private func bookContentBuilder(isCompact: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            OpenBookBackground()
            PageCurlBookView(pages: bookPages, currentPage: $currentPage)
            
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
    }
    
    @ViewBuilder
    private func frontCoverView(width: CGFloat, height: CGFloat, isCompact: Bool) -> some View {
        ZStack {
            Color(red: 0.5, green: 0.1, blue: 0.1)
            
            Rectangle()
                .stroke(Color(red: 0.8, green: 0.6, blue: 0.2), lineWidth: 4)
                .padding(10)
                
            VStack(spacing: 20) {
                Image("MotherBasket")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width * 0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
                    
                Text(lm.t("map.region.red_riding_hood"))
                    .font(.custom("Alegreya", size: isCompact ? 24 : 36, relativeTo: .title))
                    .foregroundColor(Color(red: 0.9, green: 0.8, blue: 0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(width: width, height: height)
    }

""")
        new_lines.append(line)
        continue
        
    new_lines.append(line)

with open("/Users/cirogiovannicalisto/Desktop/Progetti/CH7/Challenge-7-Apple-Accademy/Final Version/SharedUI/BookView.swift", "w") as f:
    f.writelines(new_lines)
