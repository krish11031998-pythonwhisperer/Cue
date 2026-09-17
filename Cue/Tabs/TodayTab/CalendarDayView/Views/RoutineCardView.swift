//
//  RoutineCardView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/09/2026.
//

import SwiftUI
import VanorUI
import ColorTokensKit
import SFSafeSymbols

/// Where a routine sits against the clock.
///
/// A logged routine is `completed` whatever the time. An unlogged one reads as
/// `dueNow` around its scheduled minute, `upcoming` while that minute is still
/// ahead, and `missed` once it has gone by — which is what gives the unlogged
/// card its three distinct looks.
enum RoutineStatus: Hashable {
    case completed
    case dueNow
    case upcoming
    case missed

    /// How wide either side of the scheduled time still counts as "now".
    private static let dueWindow: TimeInterval = 30 * 60

    static func status(scheduled: Date?, isLogged: Bool, now: Date) -> RoutineStatus {
        guard !isLogged else { return .completed }
        guard let scheduled else { return .upcoming }

        let interval = scheduled.timeIntervalSince(now)
        if abs(interval) <= dueWindow {
            return .dueNow
        }
        return interval > 0 ? .upcoming : .missed
    }
}

#warning("Move this to VanorUI once the Today tab redesign settles")
/// A routine on the Today page.
///
/// Logged routines keep the filled gradient the app has always used. Unlogged
/// ones no longer read as an empty outline: they carry a tint of their own
/// colour, and their border, icon and checkbox change with how the routine sits
/// against the clock, so an upcoming routine, one due right now and one that has
/// been missed are all told apart at a glance.
struct RoutineCardView: View {

    // MARK: - Task

    struct TaskModel: Hashable, Identifiable {
        let title: String
        let icon: Icon
        let isLogged: Bool
        let action: () -> Void

        init(title: String, icon: Icon, isLogged: Bool, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.isLogged = isLogged
            self.action = action
        }

        var id: Int { hashValue }

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(icon)
            hasher.combine(isLogged)
        }

        static func == (lhs: TaskModel, rhs: TaskModel) -> Bool {
            lhs.title == rhs.title && lhs.icon == rhs.icon && lhs.isLogged == rhs.isLogged
        }
    }

    // MARK: - Tag

    struct TagModel: Hashable, Identifiable {
        let name: String
        let color: Color

        init(name: String, color: Color) {
            self.name = name
            self.color = color
        }

        var id: String { name }
    }

    // MARK: - Model

    struct Model: Hashable, Identifiable {
        let title: String
        let icon: Icon
        let lightColor: Color
        let darkColor: Color
        /// The routine's scheduled moment on the day being shown, not on today.
        let scheduledDate: Date?
        let isLogged: Bool
        let tasks: [TaskModel]
        let tags: [TagModel]
        let logReminder: () -> Void
        let deleteReminder: () -> Void

        init(title: String,
             icon: Icon,
             lightColor: Color,
             darkColor: Color,
             scheduledDate: Date?,
             isLogged: Bool,
             tasks: [TaskModel] = [],
             tags: [TagModel] = [],
             logReminder: @escaping () -> Void,
             deleteReminder: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.lightColor = lightColor
            self.darkColor = darkColor
            self.scheduledDate = scheduledDate
            self.isLogged = isLogged
            self.tasks = tasks
            self.tags = tags
            self.logReminder = logReminder
            self.deleteReminder = deleteReminder
        }

        var id: Int { hashValue }

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(icon)
            hasher.combine(lightColor)
            hasher.combine(darkColor)
            hasher.combine(scheduledDate)
            hasher.combine(isLogged)
            hasher.combine(tasks)
            hasher.combine(tags)
        }

        static func == (lhs: Model, rhs: Model) -> Bool {
            lhs.title == rhs.title
            && lhs.icon == rhs.icon
            && lhs.lightColor == rhs.lightColor
            && lhs.darkColor == rhs.darkColor
            && lhs.scheduledDate == rhs.scheduledDate
            && lhs.isLogged == rhs.isLogged
            && lhs.tasks == rhs.tasks
            && lhs.tags == rhs.tags
        }
    }

    // MARK: - Layout constants

    private static let contentCoordinateSpaceName: String = "RoutineCardContent"
    private static let contentPadding: CGFloat = 16
    private static let iconSize: CGSize = .init(width: 32, height: 32)

    private let model: Model
    /// The moment the page is being read at, so the card can place itself against the clock.
    private let now: Date

    @Environment(\.colorScheme) private var colorScheme
    @State private var iconFrame: CGRect = .zero
    @State private var capsuleCornerRadius: CGFloat = .zero
    @State private var showTasks: Bool = false
    @State private var isLogged: Bool
    @State private var loggedTasks: Set<TaskModel> = .init()

    init(model: Model, now: Date) {
        self.model = model
        self.now = now
        self._isLogged = .init(initialValue: model.isLogged)
        self._loggedTasks = .init(initialValue: Set(model.tasks.filter(\.isLogged)))
    }

    private var theme: LCHColor {
        .init(color: colorScheme == .dark ? model.darkColor : model.lightColor)
    }

    private var status: RoutineStatus {
        .status(scheduled: model.scheduledDate, isLogged: isLogged, now: now)
    }

    private var hasSubtasks: Bool { !model.tasks.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentView
                .padding(.horizontal, Self.contentPadding)
                .padding(.top, Self.contentPadding)
                .padding(.bottom, hasSubtasks ? 0 : Self.contentPadding)

            if hasSubtasks {
                if showTasks {
                    SubTasksView(tasks: model.tasks, theme: theme, loggedTasks: $loggedTasks)
                }

                SubTaskDotProgressView(tasksCount: model.tasks.count,
                                       tasksCompleted: loggedTasks.count,
                                       theme: theme,
                                       showTasks: showTasks)
                .onTapGesture {
                    withAnimation(.snappy) {
                        self.showTasks.toggle()
                    }
                }
            }
        }
        .coordinateSpace(name: Self.contentCoordinateSpaceName)
        .clipped()
        .background(alignment: .bottomLeading) { cardBackground }
        .overlay { cardBorder }
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeInOut, value: showTasks)
        .contextMenu {
            Button("Delete", systemSymbol: .trash, role: .destructive) {
                model.deleteReminder()
            }
            .contentShape(.capsule)
        }
        .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
            capsuleCornerRadius = min(min(newValue.width, newValue.height) / 2, 32)
        }
        .environment(\.theme, theme)
    }

    // MARK: - Background

    /// The card's fill: the app background, a tint of the routine's own colour while
    /// it is unlogged, and the gradient that wipes over it from the icon once it is.
    private var cardBackground: some View {
        ZStack(alignment: .center) {
            RoutineCapsule()
                .fill(Color.cueItBackground)
                .shadow(color: glowColor, radius: 12, x: 0, y: 0)
                .shadow(color: colorScheme == .light ? .black.opacity(0.05) : .white.opacity(0.025),
                        radius: 4, x: 0, y: 4)

            RoutineCapsule()
                .fill(tintColor)

            LinearGradient(stops: [.init(color: Color.cueItBackground.opacity(0.25), location: 0),
                                   .init(color: theme.baseColor, location: 0.65)],
                           startPoint: .leading,
                           endPoint: .trailing)
            .mask(alignment: .center) {
                ExpandingCircle(startFrame: iconFrame,
                                finalCornerRadius: capsuleCornerRadius,
                                pct: isLogged ? 1 : 0)
            }
        }
    }

    /// The unlogged card's outline. Solid and faint while the routine is still ahead,
    /// solid and full strength while it is due, dashed once it has been missed.
    @ViewBuilder
    private var cardBorder: some View {
        switch status {
        case .completed:
            EmptyView()
        case .upcoming:
            RoutineCapsule()
                .strokeBorder(theme.baseColor.opacity(0.35),
                              style: .init(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        case .dueNow:
            RoutineCapsule()
                .strokeBorder(theme.baseColor,
                              style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
        case .missed:
            RoutineCapsule()
                .strokeBorder(theme.baseColor.opacity(0.5),
                              style: .init(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [5, 6]))
        }
    }

    private var tintColor: Color {
        switch status {
        case .completed: return .clear
        case .dueNow: return theme.surfaceSecondary
        case .upcoming, .missed: return theme.surfaceTertiary
        }
    }

    /// A halo around the silhouette of a routine that is due right now, so the card
    /// the page wants you to act on carries the most weight on screen.
    private var glowColor: Color {
        status == .dueNow ? theme.baseColor.opacity(0.35) : .clear
    }

    // MARK: - Content

    private var contentView: some View {
        HStack(alignment: .center, spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 0) {
                Text(model.title)
                    .font(.headline)
                    .foregroundStyle(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if model.scheduledDate != nil {
                    timeRow
                        .padding(.top, 4)
                }

                if !model.tags.isEmpty {
                    tagsRow
                        .padding(.top, 8)
                }
            }

            logButton
        }
    }

    private var iconView: some View {
        ReminderIconView(icon: model.icon,
                         foregroundColor: theme.foregroundPrimary,
                         backgroundColor: isLogged ? .clear : theme.surfacePrimary,
                         font: .footnote)
        .overlay {
            if status == .dueNow {
                Circle()
                    .strokeBorder(theme.baseColor, lineWidth: 2)
            }
        }
        .frame(width: Self.iconSize.width, height: Self.iconSize.height, alignment: .center)
        .onGeometryChange(for: CGRect.self,
                          of: { $0.frame(in: .named(Self.contentCoordinateSpaceName)) }) { newValue in
            if iconFrame == .zero {
                iconFrame = newValue
            }
        }
    }

    /// The scheduled time, plus how far that time is from now — the per-routine half of
    /// the page's time indication.
    private var timeRow: some View {
        HStack(alignment: .center, spacing: 6) {
            if let scheduledDate = model.scheduledDate {
                HStack(alignment: .center, spacing: 4) {
                    Image(systemSymbol: .clock)
                    Text(scheduledDate.timeBuilder())
                }
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(timeColor)
            }

            if let relativeLabel {
                Text(relativeLabel)
                    .font(.bitcountMedium(style: .caption2))
                    .foregroundStyle(theme.foregroundPrimary)
                    .padding(.init(top: 2, leading: 7, bottom: 2, trailing: 7))
                    .background(theme.surfacePrimary, in: .capsule)
            }
        }
    }

    /// At most `maxVisibleTags` tags, with the rest rolled into a "+n" chip so a
    /// heavily tagged routine cannot push the card's title out of shape.
    private static let maxVisibleTags: Int = 2

    private var tagsRow: some View {
        let visible = Array(model.tags.prefix(Self.maxVisibleTags))
        let hidden = model.tags.count - visible.count

        return HStack(alignment: .center, spacing: 4) {
            ForEach(visible) { tag in
                let tagTheme = LCHColor(color: tag.color)
                HStack(alignment: .center, spacing: 4) {
                    Image(systemSymbol: .circleFill)
                        .foregroundStyle(tagTheme.foregroundTertiary)
                    Text(tag.name)
                        .lineLimit(1)
                }
                .font(.caption2)
                .padding(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
                .background(tagTheme.backgroundSecondary, in: .capsule)
            }

            if hidden > 0 {
                Text("+\(hidden)")
                    .font(.caption2)
                    .padding(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .background(theme.surfacePrimary, in: .capsule)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Log button

    private var logButton: some View {
        Button {
            SensoryFeedbackManager.shared.playRigidImpact()
            withAnimation(.snappy(duration: 0.3, extraBounce: 0.1)) {
                self.isLogged.toggle()
            } completion: {
                model.logReminder()
            }
        } label: {
            ZStack(alignment: .center) {
                switch status {
                case .completed:
                    Circle()
                        .fill(theme.backgroundTertiary)
                    Image(systemSymbol: .checkmark)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(6)
                case .dueNow:
                    Circle()
                        .strokeBorder(theme.baseColor, lineWidth: 2)
                    Circle()
                        .fill(theme.baseColor.opacity(0.4))
                        .padding(7)
                case .upcoming:
                    Circle()
                        .strokeBorder(theme.baseColor.opacity(0.45), lineWidth: 1.5)
                case .missed:
                    Circle()
                        .strokeBorder(theme.baseColor.opacity(0.6),
                                      style: .init(lineWidth: 1.5, dash: [3, 3]))
                }
            }
            .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .frame(width: 24, height: 24, alignment: .center)
        .animation(.easeInOut, value: isLogged)
    }

    // MARK: - Colours & copy

    private var titleColor: Color {
        colorScheme == .light ? theme.foregroundTertiary : theme.foregroundPrimary
    }

    private var timeColor: Color {
        colorScheme == .light ? theme.foregroundSecondary : theme.foregroundPrimary
    }

    /// "in 25m", "now", "2h ago" — nil when the routine is done, or when it sits on a
    /// day far enough from today that a countdown would say nothing useful.
    private var relativeLabel: String? {
        guard let scheduledDate = model.scheduledDate else { return nil }

        switch status {
        case .completed:
            return nil
        case .dueNow:
            return "now"
        case .upcoming, .missed:
            guard scheduledDate.startOfDay == now.startOfDay else { return nil }
            let interval = abs(scheduledDate.timeIntervalSince(now))
            let minutes = Int(interval / 60)
            let compact: String = minutes >= 60 ? "\(minutes / 60)h" : "\(minutes)m"
            return status == .upcoming ? "in \(compact)" : "\(compact) ago"
        }
    }
}


// MARK: - Shape

/// The card's silhouette: a capsule until the card grows tall enough for its corners
/// to settle at 32pt.
private struct RoutineCapsule: InsettableShape {

    var insetAmount: CGFloat = 0

    nonisolated func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = min(min(insetRect.width, insetRect.height) / 2, 32)
        return Path { path in
            path.addRoundedRect(in: insetRect,
                                cornerRadii: .init(topLeading: radius,
                                                   bottomLeading: radius,
                                                   bottomTrailing: radius,
                                                   topTrailing: radius),
                                style: .continuous)
        }
    }

    nonisolated func inset(by amount: CGFloat) -> RoutineCapsule {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}


// MARK: - Subtasks

extension RoutineCardView {

    struct SubTasksView: View {

        let tasks: [TaskModel]
        let theme: LCHColor
        @Binding var loggedTasks: Set<TaskModel>

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(tasks.indices, id: \.self) { index in
                    let task = tasks[index]
                    SubTaskRow(isLogged: loggedTasks.contains(task), task: task, theme: theme) {
                        if loggedTasks.contains(task) {
                            loggedTasks.remove(task)
                        } else {
                            loggedTasks.insert(task)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .popIn.animation(.snappy(duration: 0.1, extraBounce: 0).delay(0.01 * Double(1 + index))),
                        removal: .opacity))
                }
            }
            .padding(.init(top: 12, leading: 16, bottom: 0, trailing: 16))
            .transition(.opacity)
        }
    }

    struct SubTaskRow: View {

        @State private var isLogged: Bool
        private let task: TaskModel
        private let theme: LCHColor
        private let countUpdate: () -> Void

        init(isLogged: Bool, task: TaskModel, theme: LCHColor, countUpdate: @escaping () -> Void) {
            self._isLogged = .init(initialValue: isLogged)
            self.task = task
            self.theme = theme
            self.countUpdate = countUpdate
        }

        var body: some View {
            Button {
                countUpdate()
                self.isLogged.toggle()
                task.action()
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    ReminderIconView(icon: task.icon,
                                     foregroundColor: theme.foregroundPrimary,
                                     backgroundColor: theme.surfacePrimary,
                                     font: .caption2)
                    .frame(width: 24, height: 24, alignment: .center)

                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .strikethrough(isLogged, color: theme.foregroundSecondary)
                        .foregroundStyle(isLogged ? theme.foregroundSecondary : theme.foregroundPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack(alignment: .center) {
                        if isLogged {
                            Circle()
                                .fill(theme.backgroundTertiary)
                            Image(systemSymbol: .checkmark)
                                .resizable()
                                .scaledToFit()
                                .transition(.symbolEffect(.drawOn))
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                                .padding(6)
                        } else {
                            Circle()
                                .strokeBorder(theme.baseColor.opacity(0.45),
                                              style: .init(lineWidth: 1.5, dash: [3, 3]))
                        }
                    }
                    .frame(width: 24, height: 24, alignment: .center)
                    .contentShape(.circle)
                    .animation(.easeInOut, value: isLogged)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    struct SubTaskDotProgressView: View {

        let tasksCount: Int
        let tasksCompleted: Int
        let theme: LCHColor
        let showTasks: Bool

        var body: some View {
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<tasksCount, id: \.self) { index in
                    Circle()
                        .fill(index < tasksCompleted ? theme.backgroundTertiary : theme.surfacePrimary)
                        .frame(width: 8, height: 8)
                }

                Text("\(tasksCompleted)/\(tasksCount)")
                    .font(.bitcountRegular(style: .caption2))
                    .foregroundStyle(Color.secondary)
                    .contentTransition(.numericText(value: Double(tasksCompleted)))
                    .padding(.leading, 5)

                Spacer(minLength: 0)

                Image(systemSymbol: .chevronDown)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)
                    .rotationEffect(.degrees(showTasks ? 180 : 0))
                    .frame(width: 24, alignment: .center)
            }
            .animation(.snappy, value: tasksCompleted)
            .padding(.init(top: RoutineCardView.contentPadding,
                           leading: RoutineCardView.contentPadding * 1.5,
                           bottom: 12,
                           trailing: RoutineCardView.contentPadding))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
    }
}
