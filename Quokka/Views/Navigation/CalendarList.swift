import SwiftUI
import SwiftData

struct CalendarList: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Query private var posts: [Post]
	@Binding var selectedPostID: Post.ID?
	@State private var confirmationDialogIsShown = false

	var body: some View {
		VStack {
			List(selection: $selectedPostID) {
				ForEach(calendarDays) { day in
					Section(header: Text(day.date.formatted(date: .complete, time: .omitted))) {
						ForEach(day.posts) { post in
							PostCapsuleView(post: post)
						} // ForEach
					} // section
				} // ForEach
			} // List
			.padding()

			// on macOS, we want the accessibility actions to be available without needing to first interact with the list to select the individual recording row
			// so adding the accessibility VO actions to the list view in addition to the RecordingRow view
			// but if we do this on iOS as well it will result in getting the accessibility actions twice
#if os(macOS)
			.addDiaryEntryVOActions(model: model, context: context, selectedPost: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
#endif
			.enableDeletingWithKeyboard(of: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
			.confirmDeletion(ofSelected: selectedPostBinding, if: $confirmationDialogIsShown)

			.overlay(Group {
				if posts.isEmpty {
					Text("Diary entries that you record or import in the “Today” view will show up here.")
						.font(.largeTitle)
						.multilineTextAlignment(.center)
				} // end if
			}) // overlay group

			.onAppear {
				if selectedPostID == nil {
					if let mostRecentDay = calendarDays.last {
						selectedPostID = mostRecentDay.posts.last?.id
					} // end if let
				} // end if
			} // on appear
		} // VStack
	} // body

	init(
		author: User?,
		selectedPostID: Binding<Post.ID?>) {
		_selectedPostID = selectedPostID
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

	var selectedPost: Post? {
		posts.first(where: { $0.id == selectedPostID } )
	}

	var selectedPostBinding: Binding<Post?> {
		Binding(
			get: { selectedPost },
			set: { newValue in
				selectedPostID = newValue?.id
			})
	} // var
} // extension
