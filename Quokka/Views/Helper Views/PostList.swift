import SwiftUI
import SwiftData

struct PostList: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	var posts: [Post]
	let overlayText: String
	@Binding var selectedPost: Post?
	@State private var confirmationDialogIsShown = false
	@State private var presented: Bool = true

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

		.inspector(isPresented: $presented) {
			if let post = selectedPost {
				PostView(post: post)
			} // if let
		} // inspect

		.overlay(Group {
			if posts.isEmpty {
				Text(overlayText)
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
} // view
