import SwiftUI
import SwiftData

struct PostList: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Query private var posts: [Post]
	let date: Date
	@Binding var selectedPost: Post?
	@State private var confirmationDialogIsShown = false

	var body: some View {
		List(posts, id: \.self, selection: $selectedPost) { post in
PostCapsuleView(post: post)
			} // List
		.frame(minWidth: 200, maxWidth: 400)
		// on macOS, we want the accessibility actions to be available without needing to first interact with the list to select the individual recording row
		// so adding the accessibility VO actions to the list view in addition to the PostCapsuleView
		// but if we do this on iOS as well it will result in getting the accessibility actions twice
		#if os(macOS)
		.addDiaryEntryVOActions(model: model, context: context, selectedPost: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
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
			var postsToDelete = [Post]()
			for index in offsets {
				postsToDelete.append(posts[index])
			}
			model.delete(postsToDelete, fromContext: context)
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

} // view
