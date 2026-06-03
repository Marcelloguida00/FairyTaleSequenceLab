import SwiftUI
import Combine

struct EnvelopeOpeningView: View {
    let event: EventData
    let onDismiss: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // --- State variables for opening sequence ---
    @State private var isOpened = false
    @State private var isAnimating = false
    @State private var shakeOffset: CGFloat = 0
    
    // Envelope stages
    @State private var flapOpenAmount: Double = 0.0 // 0 to 180 degrees flip
    @State private var showSeal = true
    @State private var sealOpacity: Double = 1.0
    @State private var burstScale: CGFloat = 0.05
    @State private var burstOpacity: Double = 0.0
    
    // Particles
    @State private var explosionParticles: [ExplosionParticle] = []
    @State private var ambientParticles: [AmbientParticle] = []
    
    // Revealed Cards state
    @State private var cardsRevealed = false
    @State private var holoOffset: CGFloat = -150
    @State private var animateShimmer = false
    
    // Button text
    @State private var statusText: String = ""
    @State private var buttonText: String = ""

    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    // Particle Structs
    struct ExplosionParticle: Identifiable {
        let id = UUID()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var size: CGFloat
        var color: Color
        var velocityX: CGFloat
        var velocityY: CGFloat
        var rotation: Double
        var rotationSpeed: Double
        var opacity: Double = 1.0
        var scale: CGFloat = 0.1
    }

    struct AmbientParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var color: Color
        var speedY: CGFloat
        var amplitude: CGFloat
        var frequency: Double
        var phase: Double
    }

    init(event: EventData, onDismiss: @escaping () -> Void) {
        self.event = event
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let envelopeScale = isLandscape ? 0.75 : 0.9
            
            ZStack {
                // Completely transparent background as requested
                Color.clear
                    .ignoresSafeArea()
                
                // Ambient floating sparkles behind everything
                ForEach(ambientParticles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .position(x: p.x, y: p.y)
                        .opacity(0.4)
                }

                VStack(spacing: 24) {
                    Spacer()
                    
                    // Main Scene containing Envelope and Revealed Cards
                    ZStack {
                        // Light Burst effect behind the cards/envelope
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [.white, Color(red: 1.00, green: 0.84, blue: 0.00), .clear]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 180
                                )
                            )
                            .frame(width: 360, height: 360)
                            .scaleEffect(burstScale)
                            .opacity(burstOpacity)
                            .blur(radius: 8)
                        
                        // Revealed Cards from the pack
                        if cardsRevealed {
                            cardsFanView(geo: geo)
                                .transition(.identity)
                                .zIndex(15)
                        }
                        
                        // Sealed/Opening Envelope
                        envelopeView()
                            .scaleEffect(envelopeScale)
                            .offset(x: shakeOffset, y: isOpened ? 120 : 0)
                            .opacity(isOpened ? 0.0 : 1.0)
                            .zIndex(10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: isOpened)
                        
                        // Explosion/Sparkle Particles
                        ForEach(explosionParticles) { p in
                            Image(systemName: "sparkle")
                                .font(.system(size: p.size))
                                .foregroundColor(p.color)
                                .scaleEffect(p.scale)
                                .rotationEffect(.degrees(p.rotation))
                                .position(x: geo.size.width / 2 + p.x, y: geo.size.height / 2 + p.y - (isOpened ? 80 : 0))
                                .opacity(p.opacity)
                        }
                    }
                    .frame(height: 380)
                    
                    Spacer()
                    
                    // Controls (Status Text and Action Button)
                    VStack(spacing: 16) {
                        Text(statusText)
                            .font(.app(.title3, weight: .bold))
                            .foregroundColor(Color(red: 1.00, green: 0.84, blue: 0.00))
                            .shadow(color: Color(red: 1.00, green: 0.67, blue: 0.00).opacity(0.5), radius: 8, y: 2)
                            .transition(.scale.combined(with: .opacity))
                            .id(statusText)
                        
                        Button(action: handleAction) {
                            Text(buttonText)
                                .font(.app(.headline, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 48)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 1.00, green: 0.84, blue: 0.00),
                                                    Color(red: 0.82, green: 0.40, blue: 0.98)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                        )
                                        .shadow(color: Color(red: 1.00, green: 0.84, blue: 0.00).opacity(0.3), radius: 12, y: 6)
                                )
                        }
                        .disabled(isAnimating)
                        .opacity(isAnimating ? 0.6 : 1.0)
                        .scaleEffect(isAnimating ? 0.97 : 1.0)
                        .animation(.easeInOut, value: isAnimating)
                    }
                    .padding(.bottom, 48)
                }
            }
            .onAppear {
                setupAmbientParticles(size: geo.size)
                statusText = lm.t("language.code") == "it" ? "Pacchetto Pronto!" : "Pack Ready!"
                buttonText = lm.t("language.code") == "it" ? "Apri" : "Open"
            }
            .onReceive(timer) { _ in
                updateParticles(size: geo.size)
            }
        }
    }

    // --- Action Handler ---
    private func handleAction() {
        if isOpened {
            // Dismiss and transition to RewardView
            onDismiss()
        } else {
            // Start opening sequence
            openPack()
        }
    }

    private func openPack() {
        guard !isAnimating else { return }
        isAnimating = true
        statusText = lm.t("language.code") == "it" ? "Estrazione..." : "Opening..."
        
        // Step 1: Shaking
        let duration = 0.5
        let steps = 10
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * (duration / Double(steps))) {
                if i == steps - 1 {
                    self.shakeOffset = 0
                } else {
                    self.shakeOffset = (i % 2 == 0 ? 8 : -8)
                }
            }
        }
        
        // Step 2: Open Flap & Fade Seal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            AppSettings.hapticSuccess()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                flapOpenAmount = 180.0
                sealOpacity = 0.0
            }
        }
        
        // Step 3: Burst of Light & Particles explosion!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            PianoChordPlayer.shared.play(.cMajor)
            triggerExplosion()
            
            withAnimation(.easeOut(duration: 0.4)) {
                burstScale = 2.0
                burstOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                burstOpacity = 0.0
            }
        }
        
        // Step 4: Cards reveal sliding out!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.8)) {
                cardsRevealed = true
                isOpened = true
            }
            
            // Shimmer animation
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                animateShimmer = true
            }
            
            statusText = lm.t("language.code") == "it" ? "Carte Sbloccate!" : "Cards Unlocked!"
            buttonText = lm.t("language.code") == "it" ? "Continua" : "Continue"
            isAnimating = false
        }
    }

    // --- Envelope Graphics (SwiftUI-based replica of requested SVG) ---
    @ViewBuilder
    private func envelopeView() -> some View {
        ZStack {
            // Envelope Back Panel
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2a2a3a"), Color(hex: "1a1a25")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 300, height: 220)
                .shadow(color: .black.opacity(0.4), radius: 15, y: 10)
            
            // Cards group sticking slightly out when flap starts to open
            if flapOpenAmount > 30 && !cardsRevealed {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1a0b2e"))
                    .frame(width: 140, height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "ffd700"), lineWidth: 2)
                    )
                    .offset(y: -40)
                    .transition(.move(edge: .bottom))
            }
            
            // Envelope Flap (Rotates on top edge)
            EnvelopeFlapShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "353545"), Color(hex: "20202e")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 300, height: 120)
                .rotation3DEffect(
                    .degrees(flapOpenAmount),
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    anchor: .top,
                    anchorZ: 0.0,
                    perspective: 0.5
                )
                .offset(y: -50) // Aligns flap top to y=0 of back panel
            
            // Envelope Pocket (Front piece that sits over the cards)
            EnvelopePocketShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "353545"), Color(hex: "20202e")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 300, height: 220)
            
            // Pocket decorative lines
            VStack {
                Spacer()
                Line()
                    .stroke(Color(hex: "ffd700").opacity(0.3), lineWidth: 1)
                    .frame(width: 240, height: 1)
                Spacer().frame(height: 12)
                Line()
                    .stroke(Color(hex: "b026ff").opacity(0.3), lineWidth: 1)
                    .frame(width: 200, height: 1)
                Spacer().frame(height: 20)
            }
            .frame(width: 300, height: 220)
            
            // Golden Seal
            if sealOpacity > 0.01 {
                ZStack {
                    Circle()
                        .fill(Color(hex: "1a1a25"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [Color(hex: "ffd700"), Color(hex: "b8860b")], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 2
                                )
                        )
                    
                    // Seal Diamond Shape
                    DiamondShape()
                        .fill(Color(hex: "ffd700"))
                        .frame(width: 14, height: 24)
                }
                .offset(y: -10)
                .opacity(sealOpacity)
            }
        }
        .frame(width: 300, height: 220)
    }

    // --- Cards Reveal View (Satisfying fan-out arch) ---
    @ViewBuilder
    private func cardsFanView(geo: GeometryProxy) -> some View {
        let isLandscape = geo.size.width > geo.size.height
        
        let cardW: CGFloat = isLandscape ? 160 : 110
        let cardH: CGFloat = cardW * 16 / 9
        
        let cardOffsets: [(x: CGFloat, y: CGFloat, rot: Double)] = [
            (x: -cardW * 1.62, y: -40, rot: -4.0),
            (x: -cardW * 0.54, y: -65, rot: -1.5),
            (x: cardW * 0.54, y: -65, rot: 1.5),
            (x: cardW * 1.62, y: -40, rot: 4.0)
        ]
        
        ZStack {
            ForEach(0..<min(4, event.cards.count), id: \.self) { idx in
                let card = event.cards[idx]
                let offsets = cardOffsets[idx]
                
                CardItemView(card: card, cardW: cardW, cardH: cardH, isShimmering: animateShimmer)
                    .offset(x: offsets.x, y: offsets.y)
                    .rotationEffect(.degrees(offsets.rot))
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 8)
            }
        }
    }

    // --- Sparkle and Ambient Particles Logic ---
    private func setupAmbientParticles(size: CGSize) {
        for _ in 0..<15 {
            ambientParticles.append(
                AmbientParticle(
                    x: CGFloat.random(in: 20...size.width - 20),
                    y: CGFloat.random(in: 40...size.height - 40),
                    size: CGFloat.random(in: 2...5),
                    color: Bool.random() ? Color(hex: "ffd700") : Color(hex: "b026ff"),
                    speedY: CGFloat.random(in: -1.0 ... -0.3),
                    amplitude: CGFloat.random(in: 10...30),
                    frequency: Double.random(in: 0.01...0.03),
                    phase: Double.random(in: 0...Double.pi * 2)
                )
            )
        }
    }

    private func triggerExplosion() {
        let colors = [Color(hex: "ffd700"), .white, Color(hex: "b026ff"), Color(hex: "00f3ff")]
        for i in 0..<45 {
            let angle = (Double.pi * 2.0 * Double(i)) / 45.0 + Double.random(in: -0.2...0.2)
            let speed = CGFloat.random(in: 5.0...15.0)
            explosionParticles.append(
                ExplosionParticle(
                    size: CGFloat.random(in: 10...22),
                    color: colors.randomElement()!,
                    velocityX: CGFloat(cos(angle)) * speed,
                    velocityY: CGFloat(sin(angle)) * speed - 2.0, // slight upward float
                    rotation: Double.random(in: 0...360),
                    rotationSpeed: Double.random(in: -8...8)
                )
            )
        }
    }

    private func updateParticles(size: CGSize) {
        // Update Explosion particles
        for idx in explosionParticles.indices {
            explosionParticles[idx].x += explosionParticles[idx].velocityX
            explosionParticles[idx].y += explosionParticles[idx].velocityY
            
            // Gravity effect
            explosionParticles[idx].velocityY += 0.25
            
            // Spin
            explosionParticles[idx].rotation += explosionParticles[idx].rotationSpeed
            
            // Fade out
            explosionParticles[idx].opacity = max(0, explosionParticles[idx].opacity - 0.02)
            
            // Scale up then down
            if explosionParticles[idx].scale < 1.0 {
                explosionParticles[idx].scale += 0.15
            } else {
                explosionParticles[idx].scale = max(0.1, explosionParticles[idx].scale - 0.015)
            }
        }
        explosionParticles.removeAll(where: { $0.opacity <= 0.01 })

        // Update Ambient particles
        for idx in ambientParticles.indices {
            ambientParticles[idx].y += ambientParticles[idx].speedY
            
            // Horizontal wave drift
            let phase = ambientParticles[idx].phase + ambientParticles[idx].frequency
            ambientParticles[idx].phase = phase
            ambientParticles[idx].x += CGFloat(sin(phase)) * 0.3
            
            // Wrap around bottom/top
            if ambientParticles[idx].y < -20 {
                ambientParticles[idx].y = size.height + 20
                ambientParticles[idx].x = CGFloat.random(in: 20...size.width - 20)
            }
        }
    }
}

// --- Card Item Subview ---
struct CardItemView: View {
    let card: CardData
    let cardW: CGFloat
    let cardH: CGFloat
    let isShimmering: Bool
    
    var body: some View {
        ZStack {
            // Card Base Background with explicit frame to prevent layout expansion
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1a0b2e"), Color(hex: "0f0518")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: cardW, height: cardH)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "ffd700"), Color(hex: "ffed4a"), Color(hex: "b8860b")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: cardW, height: cardH)
                )
            
            // Inner design border with explicit padding and frame
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "ffd700").opacity(0.35), lineWidth: 1)
                .frame(width: cardW - 8, height: cardH - 8)
            
            // Actual card scene image filling the 9:16 frame perfectly
            if UIImage(named: card.imageName) != nil {
                Image(card.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardW - 14, height: cardH - 14)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .clipped()
            } else {
                // Fallback elegant placeholder
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "ffd700").opacity(0.8))
                    
                    Text("Scena \(card.id + 1)")
                        .font(.app(.caption, weight: .bold))
                        .foregroundColor(Color(hex: "ffd700"))
                }
                .frame(width: cardW - 14, height: cardH - 14)
            }
        }
        .frame(width: cardW, height: cardH)
        .overlay(
            // Shimmer effect placed as an overlay so it is clipped and does not stretch the card frame
            GeometryReader { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.0),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: cardW * 2, height: cardH)
                    .offset(x: isShimmering ? cardW * 1.5 : -cardW * 1.5)
                    .blendMode(.colorDodge)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }
}

// --- Custom Shapes for Envelope rendering ---

struct EnvelopeFlapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct EnvelopePocketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width / 2, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height / 2))
        path.closeSubpath()
        return path
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}
