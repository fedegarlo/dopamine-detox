import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState

    private struct SessionBar: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Int
    }

    private struct Milestone: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let reached: Bool
        let icon: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Your streaks and detox hours gently motivate you to keep going.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 24)

                HStack(spacing: 16) {
                    MetricCard(title: "Streak", value: "\(appState.streak) days", subtitle: "Keep compounding clarity")
                    MetricCard(title: "Detox hours", value: "\(appState.totalFocusMinutes / 60)", subtitle: "Total time reclaimed")
                    MetricCard(title: "Index", value: "\(appState.dopamineIndex)", subtitle: "Lower is calmer")
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Detox hours this week")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart(sessionBars) { item in
                        BarMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Minutes", item.minutes)
                        )
                        .cornerRadius(8)
                        .foregroundStyle(Color.accentColor.gradient)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Milestones")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(milestones) { milestone in
                        HStack {
                            Image(systemName: milestone.icon)
                                .foregroundStyle(milestone.reached ? .accent : .secondary)
                            VStack(alignment: .leading) {
                                Text(milestone.title)
                                    .fontWeight(.medium)
                                Text(milestone.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if milestone.reached {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 32)
            }
        }
    }

    private var sessionBars: [SessionBar] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let pastSevenDays = (0..<7).reversed().map { offset -> Date in
            calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        }

        return pastSevenDays.map { day in
            let totalMinutes = appState.pastSessions
                .filter { calendar.isDate($0.startedAt, inSameDayAs: day) && !$0.aborted }
                .reduce(0) { $0 + Int($1.duration.rawValue / 60) }
            return SessionBar(date: day, minutes: totalMinutes)
        }
    }

    private var milestones: [Milestone] {
        [
            Milestone(title: "24 hours clear", detail: "Accumulate 24 detox hours", reached: appState.totalFocusMinutes >= 1_440, icon: "sun.max"),
            Milestone(title: "7 day streak", detail: "Complete a week of detoxing", reached: appState.streak >= 7, icon: "flame"),
            Milestone(title: "Index below 40", detail: "Maintain a calm baseline", reached: appState.dopamineIndex < 40, icon: "leaf")
        ]
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
