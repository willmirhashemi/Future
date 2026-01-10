import SwiftUI

struct CalendarTab: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firestoreService = FirestoreService()

    @State private var selectedDate = Date()
    @State private var events: [Event] = []
    @State private var daysToShow = 1
    @State private var showingEventDetail: Event?
    @State private var showingAddEvent = false
    @State private var currentMonth = Date()

    private let calendar = Calendar.current

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with month/year and controls
                    headerView

                    // Day selector strip
                    daySelectorStrip

                    // Timeline view
                    TimelineView(
                        events: eventsForSelectedDays,
                        selectedDate: selectedDate,
                        daysToShow: daysToShow,
                        onEventTap: { event in
                            showingEventDetail = event
                        }
                    )

                    // Month calendar (collapsible)
                    monthCalendarSection
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadEvents()
            }
            .onChange(of: selectedDate) { _ in
                loadEvents()
            }
            .sheet(item: $showingEventDetail) { event in
                EventDetailSheet(event: event, onUpdate: { updatedEvent in
                    updateEvent(updatedEvent)
                })
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventSheet(selectedDate: selectedDate, onSave: { newEvent in
                    addEvent(newEvent)
                })
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Menu button
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            // Month/Year
            Button(action: { }) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(monthYearString)
                        .font(Theme.Fonts.title())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            // Search
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            // Today badge
            Button(action: goToToday) {
                Text("\(calendar.component(.day, from: Date()))")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.small)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Day Selector Strip
    private var daySelectorStrip: some View {
        HStack(spacing: 0) {
            // Timezone indicator
            Text("CST")
                .font(Theme.Fonts.caption())
                .foregroundColor(Theme.Colors.textTertiary)
                .frame(width: 50)

            // Days
            ForEach(0..<min(daysToShow + 2, 7), id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: selectedDate)!
                DayColumnHeader(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date)
                ) {
                    selectedDate = date
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.background)
    }

    // MARK: - Month Calendar Section
    private var monthCalendarSection: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Theme.Colors.textTertiary)
                .frame(width: 40, height: 4)
                .padding(.vertical, Theme.Spacing.sm)

            // No upcoming indicator
            HStack {
                Text(upcomingEventText)
                    .font(Theme.Fonts.subheadline())
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                // Add event button
                Button(action: { showingAddEvent = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Theme.Colors.tertiaryBackground)
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)

            // Days to show toggle
            HStack {
                Text("View:")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textSecondary)

                ForEach([1, 2, 3], id: \.self) { days in
                    Button("\(days) day\(days > 1 ? "s" : "")") {
                        withAnimation {
                            daysToShow = days
                        }
                    }
                    .font(Theme.Fonts.caption())
                    .foregroundColor(daysToShow == days ? Theme.Colors.accent : Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(daysToShow == days ? Theme.Colors.accent.opacity(0.2) : Color.clear)
                    .cornerRadius(Theme.CornerRadius.small)
                }

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)
        }
        .background(Theme.Colors.secondaryBackground)
    }

    // MARK: - Computed Properties
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: selectedDate)
    }

    private var eventsForSelectedDays: [Event] {
        events.filter { event in
            for dayOffset in 0..<daysToShow {
                if let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: selectedDate),
                   calendar.isDate(event.startTime, inSameDayAs: dayDate) {
                    return true
                }
            }
            return false
        }
    }

    private var upcomingEventText: String {
        let upcomingToday = events.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: Date()) && event.startTime > Date()
        }

        if let next = upcomingToday.first {
            return "Next: \(next.title)"
        }
        return "No upcoming events"
    }

    // MARK: - Methods
    private func goToToday() {
        withAnimation {
            selectedDate = Date()
        }
    }

    private func loadEvents() {
        guard let userId = authService.currentUser?.id else { return }

        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        Task {
            events = try await firestoreService.fetchEvents(
                userId: userId,
                from: startOfMonth,
                to: endOfMonth
            )
        }
    }

    private func addEvent(_ event: Event) {
        Task {
            let newEvent = try await firestoreService.createEvent(event)
            events.append(newEvent)

            // Update user stats for manual events
            if !event.isAIGenerated, let userId = authService.currentUser?.id {
                try await firestoreService.incrementManualEventsCount(userId: userId)
            }
        }
    }

    private func updateEvent(_ event: Event) {
        Task {
            try await firestoreService.updateEvent(event)
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = event
            }
        }
    }
}

// MARK: - Day Column Header
struct DayColumnHeader: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textSecondary)

                Text("\(calendar.component(.day, from: date))")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(isToday ? .white : Theme.Colors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(isToday ? Theme.Colors.accent : Color.clear)
                    .cornerRadius(16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    let events: [Event]
    let selectedDate: Date
    let daysToShow: Int
    let onEventTap: (Event) -> Void

    private let hourHeight: CGFloat = 60
    private let startHour = 0
    private let endHour = 24
    private let calendar = Calendar.current

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Hour grid
                    VStack(spacing: 0) {
                        ForEach(startHour..<endHour, id: \.self) { hour in
                            HourRow(hour: hour, hourHeight: hourHeight)
                                .id(hour)
                        }
                    }

                    // Current time indicator
                    if calendar.isDate(selectedDate, inSameDayAs: Date()) {
                        CurrentTimeIndicator(hourHeight: hourHeight, startHour: startHour)
                    }

                    // Events
                    ForEach(events) { event in
                        EventBlock(
                            event: event,
                            hourHeight: hourHeight,
                            startHour: startHour,
                            totalDays: daysToShow
                        )
                        .onTapGesture {
                            onEventTap(event)
                        }
                    }
                }
            }
            .onAppear {
                // Scroll to current hour
                let currentHour = calendar.component(.hour, from: Date())
                withAnimation {
                    proxy.scrollTo(max(currentHour - 1, 0), anchor: .top)
                }
            }
        }
    }
}

// MARK: - Hour Row
struct HourRow: View {
    let hour: Int
    let hourHeight: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Hour label
            Text(hourString)
                .font(Theme.Fonts.caption())
                .foregroundColor(Theme.Colors.textTertiary)
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, Theme.Spacing.xs)

            // Grid line
            Rectangle()
                .fill(Theme.Colors.timelineGrid)
                .frame(height: 1)

            Spacer()
        }
        .frame(height: hourHeight)
    }

    private var hourString: String {
        if hour == 0 {
            return "12AM"
        } else if hour < 12 {
            return "\(hour)AM"
        } else if hour == 12 {
            return "12PM"
        } else {
            return "\(hour - 12)PM"
        }
    }
}

// MARK: - Current Time Indicator
struct CurrentTimeIndicator: View {
    let hourHeight: CGFloat
    let startHour: Int

    private let calendar = Calendar.current

    var body: some View {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let offset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60 * hourHeight

        HStack(spacing: 0) {
            Text(timeString)
                .font(Theme.Fonts.caption2())
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.timelineIndicator)
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, 2)

            Circle()
                .fill(Theme.Colors.timelineIndicator)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(Theme.Colors.timelineIndicator)
                .frame(height: 2)
        }
        .offset(y: offset - 4)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Event Block
struct EventBlock: View {
    let event: Event
    let hourHeight: CGFloat
    let startHour: Int
    let totalDays: Int

    private let calendar = Calendar.current
    private let leftMargin: CGFloat = 58

    var body: some View {
        let startComponents = calendar.dateComponents([.hour, .minute], from: event.startTime)
        let startOffset = CGFloat(startComponents.hour! - startHour) * hourHeight +
                         CGFloat(startComponents.minute!) / 60 * hourHeight
        let duration = event.endTime.timeIntervalSince(event.startTime)
        let height = max(CGFloat(duration / 3600) * hourHeight, 30)

        HStack(spacing: 4) {
            Rectangle()
                .fill(event.displayColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(Theme.Fonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if height > 40 {
                    Text(event.formattedTime)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            if event.isAIGenerated {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxs)
        .frame(height: height)
        .background(event.displayColor.opacity(0.9))
        .cornerRadius(Theme.CornerRadius.small)
        .padding(.leading, leftMargin)
        .padding(.trailing, Theme.Spacing.sm)
        .offset(y: startOffset)
    }
}

#Preview {
    CalendarTab()
        .environmentObject(AuthService())
        .environmentObject(ThemeManager())
}
