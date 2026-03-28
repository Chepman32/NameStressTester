import SwiftUI
import UIKit
import Combine

enum SplashState {
    case idle
    case assembling
    case holding
    case exploding
    case reassembling
    case transitioning
    case completed
}

struct LetterParticle: Identifiable, Hashable {
    let id = UUID()
    let character: Character
    var position: CGPoint
    var velocity: CGVector
    var angle: Double
    var angularVelocity: Double
    var mass: CGFloat
    var radius: CGFloat
    var target: CGPoint
    var trail: [CGPoint]
}

final class PhysicsEngine: ObservableObject {
    @Published var particles: [LetterParticle] = []

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var attractorStrength: CGFloat = 0
    private var gravity: CGFloat = 980
    private var exploding = false
    private var reassembling = false
    private let boundsInset: CGFloat = 20

    func configure(word: String, in size: CGSize) {
        let spacing: CGFloat = 34
        let totalWidth = spacing * CGFloat(word.count - 1)
        let originX = (size.width - totalWidth) / 2
        let centerY = size.height / 2

        particles = word.enumerated().map { index, character in
            let edge = index % 4
            let start: CGPoint
            switch edge {
            case 0: start = CGPoint(x: CGFloat.random(in: 0...size.width), y: -80)
            case 1: start = CGPoint(x: size.width + 80, y: CGFloat.random(in: 0...size.height))
            case 2: start = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 80)
            default: start = CGPoint(x: -80, y: CGFloat.random(in: 0...size.height))
            }
            let target = CGPoint(x: originX + CGFloat(index) * spacing, y: centerY)
            return LetterParticle(
                character: character,
                position: start,
                velocity: .zero,
                angle: Double.random(in: -0.25...0.25),
                angularVelocity: Double.random(in: -1...1),
                mass: character == "M" ? 1.5 : 1.0,
                radius: 18,
                target: target,
                trail: []
            )
        }
    }

    func start() {
        displayLink?.invalidate()
        lastTimestamp = 0
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func explode() {
        exploding = true
        reassembling = false
        attractorStrength = 0
        particles = particles.map { particle in
            var particle = particle
            let vector = CGVector(dx: CGFloat.random(in: -400...400), dy: CGFloat.random(in: -620 ... -180))
            particle.velocity = vector
            particle.angularVelocity = Double.random(in: -6...6)
            return particle
        }
    }

    func reassemble() {
        exploding = false
        reassembling = true
    }

    @objc private func step(link: CADisplayLink) {
        let dt = lastTimestamp == 0 ? 1.0 / 60.0 : link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp

        if reassembling {
            attractorStrength = min(attractorStrength + CGFloat(dt * 160), 50)
        }

        particles = particles.enumerated().map { index, particle in
            var particle = particle
            if exploding || reassembling {
                particle.velocity.dy += gravity * dt
            }

            if reassembling {
                let dx = particle.target.x - particle.position.x
                let dy = particle.target.y - particle.position.y
                particle.velocity.dx += dx * attractorStrength * dt / particle.mass
                particle.velocity.dy += dy * attractorStrength * dt / particle.mass
                particle.angularVelocity *= 0.95
                particle.angle *= 0.92
            }

            particle.position.x += particle.velocity.dx * dt
            particle.position.y += particle.velocity.dy * dt
            particle.angle += particle.angularVelocity * dt

            particle.velocity.dx *= reassembling ? 0.96 : 0.92
            particle.velocity.dy *= reassembling ? 0.96 : 0.92

            if particle.position.x < boundsInset || particle.position.x > UIScreen.main.bounds.width - boundsInset {
                particle.velocity.dx *= -0.6
            }
            if particle.position.y < boundsInset || particle.position.y > UIScreen.main.bounds.height - boundsInset {
                particle.velocity.dy *= -0.6
            }

            particle.trail.insert(particle.position, at: 0)
            particle.trail = Array(particle.trail.prefix(3))

            if reassembling,
               hypot(particle.position.x - particle.target.x, particle.position.y - particle.target.y) < 2 {
                particle.position = particle.target
                particle.velocity = .zero
                particle.angle = 0
            }
            return particle
        }
    }
}

@MainActor
final class SplashViewModel: ObservableObject {
    @Published var state: SplashState = .idle
    @Published var particles: [LetterParticle] = []
    @Published var showTagline = false
    @Published var lineVisible = false

    let engine = PhysicsEngine()
    private var observing = false

    func start(size: CGSize, onComplete: @escaping () -> Void) {
        guard observing == false else { return }
        observing = true
        engine.configure(word: "LITMUS", in: size)
        particles = engine.particles
        engine.start()

        let cancellable = engine.$particles.sink { [weak self] particles in
            self?.particles = particles
        }

        Task {
            state = .assembling
            withAnimation(LitmusMotion.bouncy) {
                particles = engine.particles.map {
                    var particle = $0
                    particle.position = particle.target
                    particle.angle = 0
                    return particle
                }
            }

            try? await Task.sleep(for: .milliseconds(450))
            state = .holding
            withAnimation(LitmusMotion.smooth) {
                lineVisible = true
                showTagline = true
            }

            try? await Task.sleep(for: .milliseconds(650))
            state = .exploding
            engine.explode()

            try? await Task.sleep(for: .milliseconds(800))
            state = .reassembling
            engine.reassemble()

            try? await Task.sleep(for: .milliseconds(550))
            state = .transitioning
            Haptics.impact(.medium)

            try? await Task.sleep(for: .milliseconds(240))
            state = .completed
            engine.stop()
            cancellable.cancel()
            onComplete()
        }
    }

    func skip(onComplete: @escaping () -> Void) {
        guard state != .completed else { return }
        state = .transitioning
        engine.stop()
        onComplete()
    }
}

struct SplashScreen: View {
    let onComplete: () -> Void

    @StateObject private var viewModel = SplashViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Brand.surface.ignoresSafeArea()

                if reduceMotion {
                    VStack(spacing: LitmusSpacing.lg) {
                        Text("LITMUS")
                            .font(LitmusTypography.hero())
                            .foregroundStyle(Brand.primary)
                        Text(String(localized: "splash.tagline"))
                            .font(LitmusTypography.bodySmall())
                            .foregroundStyle(Brand.textSecondary)
                            .kerning(2)
                    }
                    .transition(.opacity)
                } else {
                    ForEach(viewModel.particles) { particle in
                        ZStack {
                            ForEach(Array(particle.trail.enumerated()), id: \.offset) { index, point in
                                Text(String(particle.character))
                                    .font(LitmusTypography.hero())
                                    .foregroundStyle(Brand.accent.opacity([0.6, 0.3, 0.1][safe: index] ?? 0.1))
                                    .position(point)
                            }
                            Text(String(particle.character))
                                .font(LitmusTypography.hero())
                                .foregroundStyle(Brand.primary)
                                .rotationEffect(.radians(particle.angle))
                                .position(particle.position)
                        }
                    }

                    VStack(spacing: LitmusSpacing.md) {
                        Spacer()
                            .frame(height: proxy.size.height * 0.62)
                        if viewModel.lineVisible {
                            Rectangle()
                                .fill(Brand.accent.opacity(0.4))
                                .frame(width: proxy.size.width * 0.6, height: 1)
                                .transition(.scale)
                        }
                        if viewModel.showTagline {
                            Text(String(localized: "splash.tagline"))
                                .font(LitmusTypography.bodySmall())
                                .foregroundStyle(Brand.textSecondary)
                                .kerning(2)
                                .transition(.opacity)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.skip(onComplete: onComplete)
            }
            .task {
                if reduceMotion {
                    try? await Task.sleep(for: .milliseconds(900))
                    onComplete()
                } else {
                    viewModel.start(size: proxy.size, onComplete: onComplete)
                }
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
