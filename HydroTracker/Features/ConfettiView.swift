//
//  ConfettiView.swift
//  HydroTracker
//
//  Confetti celebration animation displayed when the user hits their daily goal.
//

import SwiftUI

struct ConfettiView: View {
    @Binding var trigger: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date?

    private let duration: Double = 4.0

    private static let colors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .pink, .purple, .cyan, .mint
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

                    // Gentle gravity so particles float down like Messages confetti
                    let gravity: Double = 220
                    let x = particle.startX * size.width + sin(age * particle.wobbleSpeed) * particle.wobbleAmount * 30
                    let y = particle.velocityY * age + 0.5 * gravity * age * age
                    let rotation = Angle.degrees(particle.rotationSpeed * age * 60)

                    // Fade out near the end
                    let fadeStart = duration * 0.65
                    let opacity = age > fadeStart ? max(0, 1 - (age - fadeStart) / (duration - fadeStart)) : 1.0

                    guard y < size.height + 50, opacity > 0 else { continue }

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

        // Auto-dismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            trigger = false
        }
    }

    private static func generateParticles() -> [ConfettiParticle] {
        (0..<120).map { _ in
            ConfettiParticle(
                startX: Double.random(in: 0...1),
                velocityY: Double.random(in: 20...120),
                wobbleSpeed: Double.random(in: 1.5...4.0),
                wobbleAmount: Double.random(in: 0.5...2.0),
                rotationSpeed: Double.random(in: -5...5),
                width: Double.random(in: 5...12),
                height: Double.random(in: 8...18),
                color: Self.colors.randomElement() ?? .blue,
                isCircle: Bool.random() && Bool.random(),
                delay: Double.random(in: 0...0.8)
            )
        }
    }
}

private struct ConfettiParticle {
    let startX: Double         // 0...1 fraction of screen width
    let velocityY: Double      // downward speed
    let wobbleSpeed: Double    // horizontal sine wave frequency
    let wobbleAmount: Double   // horizontal sine wave amplitude
    let rotationSpeed: Double
    let width: Double
    let height: Double
    let color: Color
    let isCircle: Bool
    let delay: Double          // stagger start times
}

#Preview {
    @Previewable @State var showConfetti = false

    ZStack {
        Color.black

        Button("Celebrate!") {
            showConfetti = true
        }
        .font(.title2.bold())
        .buttonStyle(.borderedProminent)

        ConfettiView(trigger: $showConfetti)
    }
}
