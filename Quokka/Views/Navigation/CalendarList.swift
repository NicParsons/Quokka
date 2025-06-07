import SwiftUI
import SwiftData

struct CalendarList: View {
	@Environment(Model.self) private var model
	@Query private var posts: [Post]
	@Binding var selectedPost: Post?
	@State private var confirmationDialogIsShown = false

    var body: some View {
		NavigationView {
			ScrollViewReader { proxy in
				List(selection: $selectedPost) {
					ForEach(calendarDays) { day in
						CalendarDaySection(day: day)
					} // ForEach
				} // List
				// on macOS, we want the accessibility actions to be available without needing to first interact with the list to select the individual recording row
				// so adding the accessibility VO actions to the list view in addition to the RecordingRow view
				// but if we do this on iOS as well it will result in getting the accessibility actions twice
#if os(macOS)
				.addDiaryEntryVOActions(model: model, selectedPost: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
#endif
				.enableDeletingWithKeyboard(of: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
				.confirmDeletion(ofSelected: $selectedPost, if: $confirmationDialogIsShown)
				.onAppear {
					if selectedPost == nil {
						if let mostRecentDay = calendarDays.last {
							selectedPost = mostRecentDay.posts.last
						} // end if let
					} // end if
				} // on appear
				.onChange(of: selectedPost) { oldValue, newValue in
					proxy.scrollTo(newValue)
				}
				.overlay(Group {
					if posts.isEmpty {
						Text("Diary entries that you record or import in the “Today” view will show up here.")
							.font(.largeTitle)
							.multilineTextAlignment(.center)
					}
				}) // overlay group
			} // ScrollViewReader
		} // NavigationView
		.navigationTitle(Text("Your Audio Journal"))
		.toolbar {
			#if os(iOS)
			ToolbarItem(placement: .navigationBarTrailing) {
			EditButton()
		} // ToolbarItem
		#endif
		} // Toolbar
    } // body
} // View

extension CalendarList {
	var calendarDays: [CalendarDay] {
		model.postsSortedByDay(posts)
	} // var
} // extension

struct CalendarDaySection: View {
	let day: CalendarDay

	var body: some View {
		Section(header: Text(day.date.formatted(date: .complete, time: .omitted))) {
			ForEach(day.posts) { post in
				NavigationLink {
					PostView(post: post)
				} label: {
					PostCapsuleView(post: post)
				} // navigation link
			} // ForEach
		} // section
	} // body
} // view
