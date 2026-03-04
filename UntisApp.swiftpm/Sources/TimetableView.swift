import SwiftUI

struct TimetableView: View {
    @ObservedObject var viewModel: UntisViewModel
    @State private var showingDatePicker = false

    private var dateTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(viewModel.selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(viewModel.selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(viewModel.selectedDate) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.selectedDate)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading timetable…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.loadTimetable(for: viewModel.selectedDate) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if viewModel.lessons.isEmpty {
                    ContentUnavailableView(
                        "No Lessons",
                        systemImage: "calendar.badge.checkmark",
                        description: Text("No lessons scheduled for \(dateTitle).")
                    )
                } else {
                    List(viewModel.lessons) { lesson in
                        LessonRow(lesson: lesson)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(dateTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task { await viewModel.logout() }
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        let previous = Calendar.current.date(
                            byAdding: .day, value: -1, to: viewModel.selectedDate
                        ) ?? viewModel.selectedDate
                        Task { await viewModel.loadTimetable(for: previous) }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Button {
                        showingDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                    Button {
                        let next = Calendar.current.date(
                            byAdding: .day, value: 1, to: viewModel.selectedDate
                        ) ?? viewModel.selectedDate
                        Task { await viewModel.loadTimetable(for: next) }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: viewModel.selectedDate) { date in
                    Task { await viewModel.loadTimetable(for: date) }
                }
            }
        }
    }
}

// MARK: - LessonRow

struct LessonRow: View {
    let lesson: Lesson

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .center, spacing: 2) {
                Text(lesson.formattedStartTime)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(lesson.formattedEndTime)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48)

            Rectangle()
                .frame(width: 3)
                .foregroundStyle(lesson.isCancelled ? .red : lesson.isIrregular ? .orange : .tint)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(lesson.subjectName)
                        .font(.headline)
                        .strikethrough(lesson.isCancelled)
                    if lesson.isCancelled {
                        Text("Cancelled")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    } else if lesson.isIrregular {
                        Text("Irregular")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange, in: Capsule())
                    }
                }
                if !lesson.subjectLongName.isEmpty && lesson.subjectLongName != lesson.subjectName {
                    Text(lesson.subjectLongName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    if !lesson.teacherNames.isEmpty {
                        Label(lesson.teacherNames, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !lesson.roomNames.isEmpty {
                        Label(lesson.roomNames, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let info = lesson.info, !info.isEmpty {
                    Text(info)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DatePickerSheet

struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    let onSelect: (Date) -> Void

    init(selectedDate: Date, onSelect: @escaping (Date) -> Void) {
        _date = State(initialValue: selectedDate)
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            DatePicker(
                "Select Date",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Show") {
                        onSelect(date)
                        dismiss()
                    }
                }
            }
        }
    }
}
