import SwiftUI

/// WHOOP-style circular progress ring
struct ProgressRingView: View {
    let progress: Double
    let label: String
    let sublabel: String
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    @Environment(\.appColorScheme) private var colorScheme

    init(
        progress: Double,
        label: String,
        sublabel: String,
        color: Color = AppTheme.accent,
        size: CGFloat = 100,
        lineWidth: CGFloat = 10
    ) {
        self.progress = min(1.0, max(0, progress))
        self.label = label
        self.sublabel = sublabel
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    AppTheme.ringBackground(colorScheme),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.8), color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)

            // Center content
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text(sublabel)
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
        }
        .frame(width: size, height: size)
    }
}

/// Smaller progress ring for compact displays
struct CompactProgressRing: View {
    let data: ProgressRingData
    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            ProgressRingView(
                progress: data.progress,
                label: data.label,
                sublabel: "",
                color: data.color,
                size: 70,
                lineWidth: 6
            )

            Text(data.sublabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        }
    }
}

/// Row of three progress rings
struct ProgressRingsRow: View {
    let rings: [ProgressRingData]
    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 24) {
            ForEach(rings.indices, id: \.self) { index in
                CompactProgressRing(data: rings[index])
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Large hero progress ring for main display
struct HeroProgressRing: View {
    let streakInfo: StreakInfo
    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                streakColor.opacity(0.3),
                                streakColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)

                ProgressRingView(
                    progress: min(1.0, Double(streakInfo.currentStreak) / 30.0),
                    label: "\(streakInfo.currentStreak)",
                    sublabel: "DAY STREAK",
                    color: streakColor,
                    size: 140,
                    lineWidth: 12
                )
            }

            // Streak status
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Best Streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                    Text("\(streakInfo.longestStreak) days")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Status")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                    HStack(spacing: 4) {
                        Circle()
                            .fill(streakInfo.isActiveToday ? AppTheme.success : AppTheme.warning)
                            .frame(width: 8, height: 8)
                        Text(streakInfo.isActiveToday ? "Active Today" : "Not Yet")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                    }
                }

                if streakInfo.streakAtRisk {
                    Divider()
                        .frame(height: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alert")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.error)
                        Text("At Risk!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.error)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var streakColor: Color {
        if streakInfo.currentStreak >= 30 {
            return Color(hex: "FFB020") // Gold
        } else if streakInfo.currentStreak >= 14 {
            return Color(hex: "9B5DE5") // Purple
        } else if streakInfo.currentStreak >= 7 {
            return Color(hex: "00B4D8") // Blue
        } else {
            return AppTheme.accent // Green
        }
    }
}
