import SwiftUI

/// Main calendar view - the home screen of the app
struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showSettings = false
    @State private var showProgress = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    CalendarHeaderView(
                        title: viewModel.headerTitle,
                        viewMode: viewModel.viewMode,
                        onTodayTap: viewModel.goToToday,
                        onPreviousTap: viewModel.goToPreviousPeriod,
                        onNextTap: viewModel.goToNextPeriod,
                        onViewModeToggle: viewModel.toggleViewMode
                    )

                    // Week theme (if available)
                    if let theme = viewModel.currentWeekTheme {
                        WeekThemeBanner(theme: theme)
                            .padding(.horizontal, Constants.Layout.screenPadding)
                            .padding(.bottom, 8)
                    }

                    // Calendar content
                    switch viewModel.viewMode {
                    case .week:
                        WeekView(
                            viewModel: viewModel,
                            dates: viewModel.displayDates
                        )
                    case .day:
                        DayView(
                            viewModel: viewModel,
                            date: viewModel.selectedDate
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Haptics.tap()
                        showProgress = true
                    } label: {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 17))
                            .foregroundColor(.appPrimaryText)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Haptics.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17))
                            .foregroundColor(.appPrimaryText)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showBlockDetail) {
                if let block = viewModel.selectedBlock {
                    BlockDetailSheet(
                        block: block,
                        onComplete: { viewModel.completeBlock(block) },
                        onSkip: { viewModel.skipBlock(block) },
                        onMove: { date in viewModel.moveBlock(block, to: date) },
                        onReduce: { viewModel.reduceBlock(block) },
                        onDismiss: { viewModel.dismissBlockDetail() }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $viewModel.showReflectionPrompt) {
                WeeklyReflectionView {
                    viewModel.dismissReflectionPrompt()
                    viewModel.refresh()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showProgress) {
                ProgressTrackingView()
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

/// Calendar header with navigation
struct CalendarHeaderView: View {
    let title: String
    let viewMode: CalendarViewMode
    let onTodayTap: () -> Void
    let onPreviousTap: () -> Void
    let onNextTap: () -> Void
    let onViewModeToggle: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Month/Week title
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.appPrimaryText)

                Spacer()

                // Navigation buttons
                HStack(spacing: 8) {
                    Button(action: onPreviousTap) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appSecondaryText)
                            .frame(width: 36, height: 36)
                            .background(Color.appSecondaryBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.scale)

                    Button(action: onTodayTap) {
                        Text("Today")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.appAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appAccent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.scale)

                    Button(action: onNextTap) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appSecondaryText)
                            .frame(width: 36, height: 36)
                            .background(Color.appSecondaryBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.scale)
                }
            }

            // View mode toggle
            HStack {
                Spacer()

                Picker("View", selection: .constant(viewMode)) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                .onChange(of: viewMode) { _, _ in
                    onViewModeToggle()
                }
            }
        }
        .padding(.horizontal, Constants.Layout.screenPadding)
        .padding(.vertical, 12)
    }
}

/// Week theme banner
struct WeekThemeBanner: View {
    let theme: WeeklyTheme

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.appAccent)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Week \(theme.weekNumber): \(theme.title)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appPrimaryText)

                Text(theme.focus)
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
}
