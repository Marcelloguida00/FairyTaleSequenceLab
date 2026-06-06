        func pageContainer<Content: View>(isLeft: Bool, pageNumber: Int? = nil, @ViewBuilder content: @escaping () -> Content) -> AnyView {
            AnyView(
                ZStack {
                    // Warmer, lighter cream color for classic book pages
                    Color(red: 0.98, green: 0.96, blue: 0.90)
                        .overlay(
                            // Forest image visible only at the outer corners
                            Image("FairyTaleBackground")
                                .resizable()
                                .scaledToFill()
                                .mask(
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
                                )
                                .clipped()
                        )
                    
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
