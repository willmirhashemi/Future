import SwiftUI

// MARK: - Achievement Unlock Overlay

/// Full-screen overlay shown when an achievement is unlocked
struct AchievementUnlockOverlay: View {
    let achievement: AchievementSnapshot
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showBadge = false
    @State private var showText = false
    @State private var showButton = false
    @State private var pulseScale: CGFloat = 1.0

    @Environment(\.appColorScheme) private var colorScheme

    private var metadata: AchievementMetadata {
        achievement.metadata
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(showContent ? 0.85 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Badge with effects
                badgeSection
                    .scaleEffect(showBadge ? 1 : 0.3)
                    .opacity(showBadge ? 1 : 0)

                // Text
                textSection
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 20)

                Spacer()

                // Dismiss button
                dismissButton
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)
            }
            .padding(32)
        }
        .onAppear {
            animateIn()
            Haptics.achievement()
        }
    }

    // MARK: - Badge Section

    private var badgeSection: some View {
        ZStack {
            // Outer glow pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            metadata.color.opacity(0.6),
                            metadata.color.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulseScale
                )

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            metadata.color.opacity(0.4),
                            metadata.color.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Badge circle
            Circle()
                .fill(metadata.color.opacity(0.2))
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(metadata.color.opacity(0.5), lineWidth: 2)
                )

            // Icon
            Image(systemName: metadata.icon)
                .font(.system(size: 56, weight: .medium))
                .foregroundColor(metadata.color)

            // Sparkles
            sparkles
        }
    }

    private var sparkles: some View {
        ForEach(0..<8, id: \.self) { index in
            Circle()
                .fill(metadata.color)
                .frame(width: 6, height: 6)
                .offset(y: -90)
                .rotationEffect(.degrees(Double(index) * 45))
                .opacity(showBadge ? 1 : 0)
                .scaleEffect(showBadge ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.6)
                    .delay(Double(index) * 0.05 + 0.3),
                    value: showBadge
                )
        }
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(spacing: 12) {
            Text("Achievement Unlocked!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(metadata.color)
                .textCase(.uppercase)
                .tracking(2)

            Text(metadata.displayName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(metadata.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button(action: dismiss) {
            Text("Awesome!")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(metadata.color)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Animation

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            showBadge = true
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
            showText = true
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            showButton = true
        }

        // Start pulse animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pulseScale = 1.15
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            showButton = false
            showText = false
        }

        withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
            showBadge = false
            showContent = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}

// MARK: - Achievement Unlock Modifier

/// View modifier for showing achievement unlock overlay
struct AchievementUnlockModifier: ViewModifier {
    @Binding var achievement: AchievementSnapshot?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            content

            if let achievement = achievement {
                AchievementUnlockOverlay(
                    achievement: achievement,
                    onDismiss: {
                        self.achievement = nil
                        onDismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: achievement != nil)
    }
}

extension View {
    /// Show achievement unlock overlay when an achievement is unlocked
    func achievementUnlock(
        achievement: Binding<AchievementSnapshot?>,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        modifier(AchievementUnlockModifier(
            achievement: achievement,
            onDismiss: onDismiss
        ))
    }
}

// MARK: - Haptics Extension

extension Haptics {
    /// Haptic feedback for achievement unlock
    static func achievement() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Preview

#Preview("Achievement Unlock") {
    ZStack {
        Color.black.ignoresSafeArea()

        AchievementUnlockOverlay(
            achievement: AchievementSnapshot(
                type: .weekWarrior,
                isUnlocked: true,
                progress: 7,
                unlockedAt: Date()
            ),
            onDismiss: {}
        )
    }
}
