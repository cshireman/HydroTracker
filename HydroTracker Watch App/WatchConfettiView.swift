//
//  WatchConfettiView.swift
//  HydroTracker Watch App
//
//  Confetti celebration animation for watchOS, optimized for smaller screens.
//

#if os(watchOS)
import SwiftUI

struct WatchConfettiView: View {
    @Binding var trigger: Bool

    @State private var particles: [WatchConfettiParticle] = []
    @State private var startTime: Date?

    private let duration: Double = 3.5

    private static let colors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .pink, .purple, .cyan
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed: Double = {
                if let start = startTime {
                    return timeline.date.timeIntervalSince(start)
                }
                return 0
            }()

            Canvas { context, size in
                guard elapsed > 0, elapsed < duration else { return }

                for particle in particles {
                    let age = elapsed - particle.delay
                    guard age > 0 else { continue }

                    let gravity: Double = 180
                    let x = particle.startX * size.width + sin(age * particle.wobbleSpeed) * particle.wobbleAmount * 20
                    let y = particle.velocityY * age + 0.5 * gravity * age * age
                    let rotation = Angle.degrees(particle.rotationSpeed * age * 60)

                    let fadeStart = duration * 0.65
                    let opacity = age > fadeStart ? max(0, 1 - (age - fadeStart) / (duration - fadeStart)) : 1.0

                    guard y < size.height + 30, opacity > 0 else { continue }

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)

                    let rect = CGRect(
                        x: -particle.width / 2,
                        y: -particle.height / 2,
                        width: particle.width,
                        height: particle.height
                    )

                    if particle.isCircle {
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(particle.color)
                        )
                    } else {
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: 1),
                            with: .color(particle.color)
                        )
                    }

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                    context.opacity = 1.0
                }
            }
        }
        .onChange(of: trigger) { _, isActive in
            if isActive {
                startAnimation()
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func startAnimation() {
        particles = Self.generateParticles()
        startTime = .now

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            trigger = false
        }
    }

    private static func generateParticles() -> [WatchConfettiParticle] {
        (0..<50).map { _ in
            WatchConfettiParticle(
                startX: Double.random(in: 0...1),
                velocityY: Double.random(in: 15...90),
                wobbleSpeed: Double.random(in: 1.5...4.0),
                wobbleAmount: Double.random(in: 0.4...1.5),
                rotationSpeed: Double.random(in: -5...5),
                width: Double.random(in: 3...8),
                height: Double.random(in: 5...12),
                color: Self.colors.randomElement() ?? .blue,
                isCircle: Bool.random() && Bool.random(),
                delay: Double.random(in: 0...0.6)
            )
        }
    }
}

private struct WatchConfettiParticle {
    let startX: Double
    let velocityY: Double
    let wobbleSpeed: Double
    let wobbleAmount: Double
    let rotationSpeed: Double
    let width: Double
    let height: Double
    let color: Color
    let isCircle: Bool
    let delay: Double
}

#Preview {
    @Previewable @State var showConfetti = false

    ZStack {
        Color.black.opacity(0.2)

        Button("Celebrate!") {
            showConfetti = true
        }
        .font(.headline)
        .buttonStyle(.borderedProminent)

        WatchConfettiView(trigger: $showConfetti)
    }
}
#endif
