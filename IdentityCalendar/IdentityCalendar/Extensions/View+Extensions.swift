import SwiftUI

extension View {
    // MARK: - Card Styling

    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    func softCardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Color.appSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Button Styling

    func primaryButtonStyle() -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.appAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.body.weight(.medium))
            .foregroundColor(.appAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.appAccent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func tertiaryButtonStyle() -> some View {
        self
            .font(.body.weight(.medium))
            .foregroundColor(.appSecondaryText)
    }

    // MARK: - Text Styling

    func headlineStyle() -> some View {
        self
            .font(.system(size: 28, weight: .bold, design: .default))
            .foregroundColor(.appPrimaryText)
    }

    func titleStyle() -> some View {
        self
            .font(.title2.weight(.semibold))
            .foregroundColor(.appPrimaryText)
    }

    func subtitleStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(.appSecondaryText)
    }

    func captionStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(.appTertiaryText)
    }

    // MARK: - Layout Helpers

    func screenPadding() -> some View {
        self.padding(.horizontal, 20)
    }

    func sectionPadding() -> some View {
        self.padding(.vertical, 12)
    }

    // MARK: - Conditional Modifiers

    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<T, Transform: View>(_ value: T?, transform: (Self, T) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }

    // MARK: - Animation

    func subtleAppear() -> some View {
        self
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    func slideUp() -> some View {
        self
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Haptic Feedback

    func withHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
        )
    }

    // MARK: - Safe Area

    func ignoresSafeAreaTop() -> some View {
        self.ignoresSafeArea(.container, edges: .top)
    }

    func ignoresSafeAreaBottom() -> some View {
        self.ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - Shimmer Effect (for loading states)

    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Custom Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
}

extension ButtonStyle where Self == SoftButtonStyle {
    static var soft: SoftButtonStyle { SoftButtonStyle() }
}

// MARK: - Navigation Bar Appearance

extension View {
    func configureNavigationBar(
        backgroundColor: UIColor = .systemBackground,
        foregroundColor: UIColor = .label
    ) -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.titleTextAttributes = [.foregroundColor: foregroundColor]
            appearance.largeTitleTextAttributes = [.foregroundColor: foregroundColor]

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
