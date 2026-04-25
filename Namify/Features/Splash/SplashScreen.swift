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
    private var canvasSize: CGSize = .zero
    private var gravity: CGFloat = 980
    private var exploding = false
    private var reassembling = false
    private let boundsInset: CGFloat = 20

    func configure(word: String, in size: CGSize) {
        stop()
        canvasSize = size
        attractorStrength = 0
        exploding = false
        reassembling = false

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
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 45, maximum: 60, preferred: 60)
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

    func particlesAtTargets() -> [LetterParticle] {
        particles.map { particle in
            var particle = particle
            particle.position = particle.target
            particle.velocity = .zero
            particle.angle = 0
            particle.angularVelocity = 0
            particle.trail = []
            return particle
        }
    }

    func settleAtTargets() {
        exploding = false
        reassembling = false
        attractorStrength = 0
        particles = particlesAtTargets()
    }

    var isNearlySettled: Bool {
        particles.allSatisfy { particle in
            let dx = particle.position.x - particle.target.x
            let dy = particle.position.y - particle.target.y
            let speed = sqrt(particle.velocity.dx * particle.velocity.dx + particle.velocity.dy * particle.velocity.dy)

            return sqrt(dx * dx + dy * dy) < 5 && speed < 35 && abs(particle.angle) < 0.12
        }
    }

    @objc private func step(link: CADisplayLink) {
        let elapsed = lastTimestamp == 0 ? 1.0 / 60.0 : link.timestamp - lastTimestamp
        let dt = min(max(elapsed, 0), 1.0 / 30.0)
        lastTimestamp = link.timestamp

        if reassembling {
            attractorStrength = min(attractorStrength + CGFloat(dt * 220), 85)
        }

        particles = particles.map { particle in
            var particle = particle
            if exploding {
                particle.velocity.dy += gravity * dt
            }

            if reassembling {
                let dx = particle.target.x - particle.position.x
                let dy = particle.target.y - particle.position.y
                particle.velocity.dx += dx * attractorStrength * dt / particle.mass
                particle.velocity.dy += dy * attractorStrength * dt / particle.mass
                particle.angularVelocity *= pow(0.84, CGFloat(dt * 60))
                particle.angle *= pow(0.88, CGFloat(dt * 60))
            }

            particle.position.x += particle.velocity.dx * dt
            particle.position.y += particle.velocity.dy * dt
            particle.angle += particle.angularVelocity * dt

            let damping = pow(reassembling ? 0.90 : 0.92, CGFloat(dt * 60))
            particle.velocity.dx *= damping
            particle.velocity.dy *= damping

            let maxX = max(boundsInset, canvasSize.width - boundsInset)
            let maxY = max(boundsInset, canvasSize.height - boundsInset)
            if particle.position.x < boundsInset {
                particle.position.x = boundsInset
                particle.velocity.dx = abs(particle.velocity.dx) * 0.6
            } else if particle.position.x > maxX {
                particle.position.x = maxX
                particle.velocity.dx = -abs(particle.velocity.dx) * 0.6
            }

            if particle.position.y < boundsInset {
                particle.position.y = boundsInset
                particle.velocity.dy = abs(particle.velocity.dy) * 0.6
            } else if particle.position.y > maxY {
                particle.position.y = maxY
                particle.velocity.dy = -abs(particle.velocity.dy) * 0.6
            }

            particle.trail.insert(particle.position, at: 0)
            particle.trail = Array(particle.trail.prefix(3))

            if reassembling,
               hypot(particle.position.x - particle.target.x, particle.position.y - particle.target.y) < 2,
               hypot(particle.velocity.dx, particle.velocity.dy) < 20 {
                particle.position = particle.target
                particle.velocity = .zero
                particle.angle = 0
                particle.angularVelocity = 0
                particle.trail = []
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
    private var particleCancellable: AnyCancellable?
    private var animationTask: Task<Void, Never>?
    private var hasCompleted = false

    func start(size: CGSize, onComplete: @escaping () -> Void) {
        guard animationTask == nil, hasCompleted == false else { return }
        engine.configure(word: "NAMIFY", in: size)
        particles = engine.particles

        animationTask = Task { [weak self] in
            guard let self else { return }

            state = .assembling
            withAnimation(.spring(response: 0.76, dampingFraction: 0.78)) {
                self.particles = self.engine.particlesAtTargets()
            }

            guard await pause(milliseconds: 760) else { return }
            engine.settleAtTargets()
            particles = engine.particles

            state = .holding
            withAnimation(NamifyMotion.smooth) {
                self.lineVisible = true
                self.showTagline = true
            }

            guard await pause(milliseconds: 700) else { return }
            observeEngine()
            engine.start()
            state = .exploding
            engine.explode()

            guard await pause(milliseconds: 820) else { return }
            state = .reassembling
            engine.reassemble()

            guard await waitForReassembly() else { return }
            state = .transitioning
            Haptics.impact(.medium)

            engine.stop()
            particleCancellable?.cancel()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.92)) {
                self.particles = self.engine.particlesAtTargets()
            }
            engine.settleAtTargets()

            guard await pause(milliseconds: 420) else { return }
            complete(onComplete: onComplete)
        }
    }

    func skip(onComplete: @escaping () -> Void) {
        guard state != .completed else { return }
        animationTask?.cancel()
        animationTask = nil
        state = .transitioning
        engine.stop()
        particleCancellable?.cancel()
        complete(onComplete: onComplete)
    }

    func finish(onComplete: @escaping () -> Void) {
        animationTask?.cancel()
        animationTask = nil
        complete(onComplete: onComplete)
    }

    private func observeEngine() {
        particleCancellable?.cancel()
        particleCancellable = engine.$particles.sink { [weak self] particles in
            self?.particles = particles
        }
    }

    private func pause(milliseconds: Int) async -> Bool {
        do {
            try await Task.sleep(for: .milliseconds(milliseconds))
            return Task.isCancelled == false
        } catch {
            return false
        }
    }

    private func waitForReassembly() async -> Bool {
        var elapsed = 0
        let minimumDuration = 880
        let maximumDuration = 1_520
        let frameInterval = 40

        while elapsed < maximumDuration {
            guard await pause(milliseconds: frameInterval) else { return false }
            elapsed += frameInterval

            if elapsed >= minimumDuration, engine.isNearlySettled {
                return true
            }
        }

        return Task.isCancelled == false
    }

    private func complete(onComplete: () -> Void) {
        guard hasCompleted == false else { return }
        hasCompleted = true
        state = .completed
        animationTask = nil
        engine.stop()
        particleCancellable?.cancel()
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
                    VStack(spacing: NamifySpacing.lg) {
                        Text("NAMIFY")
                            .font(NamifyTypography.hero())
                            .foregroundStyle(Brand.primary)
                        Text(L("splash.tagline"))
                            .font(NamifyTypography.bodySmall())
                            .foregroundStyle(Brand.textSecondary)
                            .kerning(2)
                    }
                    .transition(.opacity)
                } else {
                    ForEach(viewModel.particles) { particle in
                        ZStack {
                            ForEach(Array(particle.trail.enumerated()), id: \.offset) { index, point in
                                Text(String(particle.character))
                                    .font(NamifyTypography.hero())
                                    .foregroundStyle(Brand.accent.opacity([0.6, 0.3, 0.1][safe: index] ?? 0.1))
                                    .position(point)
                            }
                            Text(String(particle.character))
                                .font(NamifyTypography.hero())
                                .foregroundStyle(Brand.primary)
                                .rotationEffect(.radians(particle.angle))
                                .position(particle.position)
                        }
                    }

                    VStack(spacing: NamifySpacing.md) {
                        Spacer()
                            .frame(height: proxy.size.height * 0.62)
                        if viewModel.lineVisible {
                            Rectangle()
                                .fill(Brand.accent.opacity(0.4))
                                .frame(width: proxy.size.width * 0.6, height: 1)
                                .transition(.scale)
                        }
                        if viewModel.showTagline {
                            Text(L("splash.tagline"))
                                .font(NamifyTypography.bodySmall())
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
                    viewModel.finish(onComplete: onComplete)
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
