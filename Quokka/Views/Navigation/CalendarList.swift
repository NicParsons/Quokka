import SwiftUI
import SwiftData

struct CalendarList: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Query private var posts: [Post]
	@Binding var selectedPost: Post?
	@SceneStorage("selectedPostIDCalendarList") private var selectedPostID: Post.ID?
	@State private var confirmationDialogIsShown = false

	var body: some View {
		VStack {
			List(selection: $selectedPost) {
				ForEach(calendarDays) { day in
					Section(header: Text(day.date.formatted(date: .complete, time: .omitted))) {
						ForEach(day.posts) { post in
							PostCapsuleView(post: post)
						} // ForEach
					} // section
				} // ForEach
			} // List
			// on macOS, we want the accessibility actions to be available without needing to first interact with the list to select the individual recording row
			// so adding the accessibility VO actions to the list view in addition to the RecordingRow view
			// but if we do this on iOS as well it will result in getting the accessibility actions twice
#if os(macOS)
			.addDiaryEntryVOActions(model: model, context: context, selectedPost: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
#endif
			.enableDeletingWithKeyboard(of: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
			.confirmDeletion(ofSelected: $selectedPost, if: $confirmationDialogIsShown)
			.overlay(Group {
				if posts.isEmpty {
					Text("Diary entries that you record or import in the “Today” view will show up here.")
						.font(.largeTitle)
						.multilineTextAlignment(.center)
				} // end if
			}) // overlay group
			.onAppear {
				if let postID = selectedPostID {
					selectedPost = posts[postID]
				} // end if

				if selectedPost == nil {
					print("No selectedPost in CalendarList View.")
					if let mostRecentDay = calendarDays.last {
						selectedPost = mostRecentDay.posts.last
						print("Programatically selected \(selectedPost?.description ?? "nothing").")
					} // end if let
				} // end if
			} // on appear

			.onChange(of: selectedPost) { oldValue, newValue in
				print("Changed selectedPost to \(newValue?.description ?? "nil").")
						selectedPostID = newValue?.id
					} // on change

			Text("Currently, \(selectedPost?.description ?? "nothing") is selected.")
		} // VStack
	} // body

	init(
		author: User?,
	selectedPost: Binding<Post?>) {
		_selectedPost = selectedPost
		let predicate: Predicate<Post>
		if let author = author {
			predicate = Post.predicate(authorID: author.id)
		} else {
			predicate = Post.anyAurthor()
		}
		_posts = Query(filter: predicate, sort: \.date, order: .forward)
	} // init
} // View

extension CalendarList {
	var calendarDays: [CalendarDay] {
		model.postsSortedByDay(posts)
	} // var
} // extension
