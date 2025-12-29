import UIKit

/// Centralized haptic feedback manager
enum Haptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Impact Feedback

    static func light() {
        lightGenerator.impactOccurred()
    }

    static func medium() {
        mediumGenerator.impactOccurred()
    }

    static func heavy() {
        heavyGenerator.impactOccurred()
    }

    // MARK: - Selection Feedback

    static func selection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Notification Feedback

    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    // MARK: - Semantic Feedback

    /// Button tap feedback
    static func tap() {
        light()
    }

    /// Navigation or page change
    static func navigate() {
        selection()
    }

    /// Completed an action successfully
    static func complete() {
        success()
    }

    /// Selected an option
    static func select() {
        selection()
    }

    /// Toggle switch changed
    static func toggle() {
        light()
    }

    /// Slider value changed
    static func slide() {
        selection()
    }

    /// Something was deleted
    static func delete() {
        medium()
    }

    /// Long press recognized
    static func longPress() {
        medium()
    }

    // MARK: - Prepare Generators

    static func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
}
