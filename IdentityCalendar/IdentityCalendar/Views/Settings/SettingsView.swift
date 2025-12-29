import SwiftUI

/// App settings and goal configuration
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Subscription section
                Section {
                    SubscriptionRow(
                        statusText: viewModel.subscriptionStatusText,
                        isPremium: viewModel.isPremium,
                        onUpgrade: viewModel.showUpgrade
                    )
                }

                // Goal settings (if active goal exists)
                if viewModel.activeGoal != nil {
                    Section("Goal Settings") {
                        // Pause/Resume
                        if viewModel.isPaused {
                            Button(action: viewModel.resumeGoal) {
                                SettingsRow(
                                    icon: "play.circle",
                                    iconColor: .appSuccess,
                                    title: "Resume Goal"
                                )
                            }
                        } else {
                            Button(action: { viewModel.showPauseConfirmation = true }) {
                                SettingsRow(
                                    icon: "pause.circle",
                                    iconColor: .appWarning,
                                    title: "Pause Goal"
                                )
                            }
                        }

                        // Availability
                        NavigationLink {
                            AvailabilitySettingsView(
                                selected: viewModel.availability,
                                onSelect: viewModel.updateAvailability
                            )
                        } label: {
                            SettingsRow(
                                icon: "clock",
                                iconColor: .appAccent,
                                title: "Availability",
                                value: viewModel.availability.displayName
                            )
                        }

                        // Intensity
                        NavigationLink {
                            IntensitySettingsView(
                                selected: viewModel.intensity,
                                onSelect: viewModel.updateIntensity
                            )
                        } label: {
                            SettingsRow(
                                icon: "speedometer",
                                iconColor: .appAccent,
                                title: "Intensity",
                                value: viewModel.intensity.displayName
                            )
                        }

                        // Plan confidence
                        NavigationLink {
                            ConfidenceSettingsView(
                                value: $viewModel.planConfidenceValue,
                                onChange: viewModel.updatePlanConfidence
                            )
                        } label: {
                            SettingsRow(
                                icon: "slider.horizontal.3",
                                iconColor: .appAccent,
                                title: "Plan Ambition",
                                value: viewModel.planConfidence.displayName
                            )
                        }
                    }
                }

                // Notifications section
                Section("Notifications") {
                    Toggle(isOn: $viewModel.blockRemindersEnabled) {
                        SettingsRow(
                            icon: "bell",
                            iconColor: .appAccent,
                            title: "Block Reminders"
                        )
                    }
                    .onChange(of: viewModel.blockRemindersEnabled) { _, newValue in
                        viewModel.toggleBlockReminders(newValue)
                    }

                    Toggle(isOn: $viewModel.reflectionRemindersEnabled) {
                        SettingsRow(
                            icon: "calendar.badge.clock",
                            iconColor: .appAccent,
                            title: "Weekly Reflection"
                        )
                    }
                    .onChange(of: viewModel.reflectionRemindersEnabled) { _, newValue in
                        viewModel.toggleReflectionReminders(newValue)
                    }

                    Toggle(isOn: $viewModel.quietHoursEnabled) {
                        SettingsRow(
                            icon: "moon",
                            iconColor: .appAccent,
                            title: "Quiet Hours"
                        )
                    }
                    .onChange(of: viewModel.quietHoursEnabled) { _, newValue in
                        viewModel.toggleQuietHours(newValue)
                    }

                    if viewModel.quietHoursEnabled {
                        DatePicker(
                            "Start",
                            selection: $viewModel.quietHoursStart,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: viewModel.quietHoursStart) { _, _ in
                            viewModel.updateQuietHours(
                                start: viewModel.quietHoursStart,
                                end: viewModel.quietHoursEnd
                            )
                        }

                        DatePicker(
                            "End",
                            selection: $viewModel.quietHoursEnd,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: viewModel.quietHoursEnd) { _, _ in
                            viewModel.updateQuietHours(
                                start: viewModel.quietHoursStart,
                                end: viewModel.quietHoursEnd
                            )
                        }
                    }
                }

                // Support section
                Section("Support") {
                    Button(action: viewModel.openSupport) {
                        SettingsRow(
                            icon: "questionmark.circle",
                            iconColor: .appSecondaryText,
                            title: "Help & Support"
                        )
                    }

                    Button(action: viewModel.openPrivacyPolicy) {
                        SettingsRow(
                            icon: "hand.raised",
                            iconColor: .appSecondaryText,
                            title: "Privacy Policy"
                        )
                    }

                    Button(action: viewModel.openTermsOfService) {
                        SettingsRow(
                            icon: "doc.text",
                            iconColor: .appSecondaryText,
                            title: "Terms of Service"
                        )
                    }
                }

                // Danger zone
                if viewModel.activeGoal != nil {
                    Section {
                        Button(role: .destructive, action: { viewModel.showResetConfirmation = true }) {
                            SettingsRow(
                                icon: "trash",
                                iconColor: .red,
                                title: "Reset Goal"
                            )
                        }
                    } footer: {
                        Text("This will delete your current goal and all progress. This action cannot be undone.")
                            .font(.caption)
                    }
                }

                // App info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.appSecondaryText)
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Button("Reset All Data") {
                        viewModel.resetAllData()
                    }
                    .foregroundColor(.red)
                }
                #endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView(source: .settings) {
                    viewModel.dismissPaywall()
                }
            }
            .confirmationDialog(
                "Pause your goal?",
                isPresented: $viewModel.showPauseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Pause Goal", role: .destructive, action: viewModel.pauseGoal)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can resume anytime. Your progress will be saved.")
            }
            .confirmationDialog(
                "Reset your goal?",
                isPresented: $viewModel.showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Goal", role: .destructive, action: viewModel.resetGoal)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete your goal and all progress. This cannot be undone.")
            }
        }
    }
}

/// Settings row with icon
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.appPrimaryText)

            if let value = value {
                Spacer()
                Text(value)
                    .foregroundColor(.appSecondaryText)
            }
        }
    }
}

/// Subscription status row
struct SubscriptionRow: View {
    let statusText: String
    let isPremium: Bool
    let onUpgrade: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appPrimaryText)

                if !isPremium {
                    Text("Upgrade for unlimited features")
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                }
            }

            Spacer()

            if !isPremium {
                Button("Upgrade") {
                    onUpgrade()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.appAccent)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

/// Availability settings subview
struct AvailabilitySettingsView: View {
    let selected: Availability
    let onSelect: (Availability) -> Void

    var body: some View {
        List {
            ForEach(Availability.allCases, id: \.self) { availability in
                Button(action: { onSelect(availability) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(availability.displayName)
                                .foregroundColor(.appPrimaryText)
                            Text(availability.description)
                                .font(.caption)
                                .foregroundColor(.appSecondaryText)
                        }

                        Spacer()

                        if availability == selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Availability")
    }
}

/// Intensity settings subview
struct IntensitySettingsView: View {
    let selected: Intensity
    let onSelect: (Intensity) -> Void

    var body: some View {
        List {
            ForEach(Intensity.allCases, id: \.self) { intensity in
                Button(action: { onSelect(intensity) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(intensity.displayName)
                                .foregroundColor(.appPrimaryText)
                            Text(intensity.description)
                                .font(.caption)
                                .foregroundColor(.appSecondaryText)
                        }

                        Spacer()

                        if intensity == selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Intensity")
    }
}

/// Confidence settings subview
struct ConfidenceSettingsView: View {
    @Binding var value: Double
    let onChange: (Double) -> Void

    var body: some View {
        List {
            Section {
                ConfidenceSlider(value: $value)
                    .padding(.vertical, 8)
            } footer: {
                Text("Adjusting this will affect how many blocks are scheduled and how long they are.")
            }
        }
        .navigationTitle("Plan Ambition")
        .onChange(of: value) { _, newValue in
            onChange(newValue)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
