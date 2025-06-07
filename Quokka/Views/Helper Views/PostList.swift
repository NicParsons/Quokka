import SwiftUI
import SwiftData

struct PostList: View {
	@Environment(Model.self) private var model
	@Query private var posts: [Post]
	let date: Date
	@Binding var selectedPost: Post?
	@State private var confirmationDialogIsShown = false

	var body: some View {
		List(posts, id: \.self, selection: $selectedPost) { post in
PostCapsuleView(post: post)
			} // List
		// .focusedSceneValue(\.recording, selected?.recording)
		.frame(minWidth: 200, maxWidth: 400)
		// on macOS, we want the accessibility actions to be available without needing to first interact with the list to select the individual recording row
		// so adding the accessibility VO actions to the list view in addition to the PostCapsuleView
		// but if we do this on iOS as well it will result in getting the accessibility actions twice
		#if os(macOS)
		.addDiaryEntryVOActions(model: model, selectedPost: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
		#endif

		.enableDeletingWithKeyboard(of: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
		.confirmDeletion(ofSelected: $selectedPost, if: $confirmationDialogIsShown)
		.overlay(Group {
			if posts.isEmpty {
				Text("You haven't recorded a diary entry for \(date.stringWithRelativeFormatting().lowercased()) yet. Hit the “Record” button to get started.")
					.font(.largeTitle)
			} // end if
		}) // overlay group
	} // body

	// if we later allow multiple selections
	func delete(at offsets: IndexSet) {
			var files = [URL]()
			for index in offsets {
				files.append(posts[index].recording.fileURL)
			}
			model.delete(files)
		}

	init(
		date: Date,
		selectedPost: Binding<Post?>,
		sortOrder: SortOrder = .forward
	) {
		self.date = date
		_selectedPost = selectedPost
		let predicate = Post.predicate(date: date)
		_posts = Query(filter: predicate, sort: \.date, order: sortOrder)
	}

	/* if we ever want a simpler way to initialise this view, we could use the following code
	init(recordings: [Recording]) {
		self.recordings = recordings
		self.date = nil
	}

	 // but if we use a custom initialiser we have to replace the default initialiser as well
	init(recordings: [Recording], date: Date) {
		self.recordings = recordings
		self.date = date
	}

	 // and we'd also have to make the date constant an optional,
	 // conditionally force unwrap it in the Text view, and
	 // provide an alternative string to use if it is nil
	 // or derive the date from the date of one of the recordings
	 */
} // view
