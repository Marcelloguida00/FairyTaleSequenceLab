with open("/Users/cirogiovannicalisto/Desktop/Progetti/CH7/Challenge-7-Apple-Accademy/Final Version/SharedUI/BookView.swift", "r") as f:
    content = f.read()

# We need to replace the ZStack inside body
# It starts with ZStack(alignment: .topTrailing) {
# and ends with .offset(x: isCompact ? 15 : 30, y: isCompact ? 10 : 20)\n                }
# followed by .aspectRatio(1.5, contentMode: .fit)

import re
# Find the exact string
start_str = "ZStack(alignment: .topTrailing) {\n                    OpenBookBackground()"
start_idx = content.find(start_str)

if start_idx == -1:
    print("Could not find start_str")
    exit(1)

# Now find the end of this block
end_str = ".offset(x: isCompact ? 15 : 30, y: isCompact ? 10 : 20)\n                }"
end_idx = content.find(end_str, start_idx) + len(end_str)

if end_idx == -1:
    print("Could not find end_str")
    exit(1)

replacement = """Color.clear
                    .aspectRatio(1.5, contentMode: .fit)
                    .overlay(
                        GeometryReader { bookGeom in
                            let w = bookGeom.size.width
                            let h = bookGeom.size.height
                            
                            ZStack {
                                // Right Half (Sempre fermo)
                                bookContentBuilder(isCompact: isCompact)
                                    .frame(width: w, height: h)
                                    .mask(
                                        Rectangle()
                                            .frame(width: w / 2)
                                            .offset(x: w / 4)
                                    )
                                
                                // Left Half (Ruota)
                                ZStack {
                                    bookContentBuilder(isCompact: isCompact)
                                        .frame(width: w, height: h)
                                        .mask(
                                            Rectangle()
                                                .frame(width: w / 2)
                                                .offset(x: -w / 4)
                                        )
                                        .opacity(isBookOpen ? 1 : 0)
                                        
                                    // Front Cover
                                    frontCoverView(width: w / 2, height: h, isCompact: isCompact)
                                        .offset(x: -w / 4)
                                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                        .opacity(isBookOpen ? 0 : 1)
                                }
                                .rotation3DEffect(
                                    .degrees(isBookOpen ? 0 : 180),
                                    axis: (x: 0, y: 1, z: 0),
                                    anchor: .center,
                                    perspective: 0.3
                                )
                                .zIndex(isBookOpen ? 0 : 1)
                            }
                            .offset(x: isBookOpen ? 0 : -w / 4)
                        }
                    )"""

# Also we need to remove the `.aspectRatio(1.5, contentMode: .fit)` that followed the original ZStack,
# because we added it to `Color.clear`.
# Let's just find it and remove it.
next_aspect = content.find(".aspectRatio(1.5, contentMode: .fit)", end_idx)
if next_aspect != -1 and next_aspect < end_idx + 100:
    content = content[:start_idx] + replacement + content[next_aspect + len(".aspectRatio(1.5, contentMode: .fit)"):]
else:
    content = content[:start_idx] + replacement + content[end_idx:]

with open("/Users/cirogiovannicalisto/Desktop/Progetti/CH7/Challenge-7-Apple-Accademy/Final Version/SharedUI/BookView.swift", "w") as f:
    f.write(content)

print("Replaced ZStack!")
