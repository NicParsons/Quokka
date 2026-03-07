import SwiftUI
import SwiftData

struct AuthorlessPosts: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Query private var posts: [Post]
	@State private var selectedPostID: Post.ID?
	@State private var inspectorIsPresented = true
	@State private var confirmationDialogIsShown = false

    var body: some View {
		NavigationView {
			List(posts, selection: $selectedPostID) { post in
				PostCapsuleView(post: post)
			} // list
			.padding()
			.frame(minWidth: 320, idealWidth: 393)

			// on macOS, we want the accessibility actions to be available without needing to first interact with the list to select the individual recording row
			// so adding the accessibility VO actions to the list view in addition to the RecordingRow view
			// but if we do this on iOS as well it will result in getting the accessibility actions twice
#if os(macOS)
			.addDiaryEntryVOActions(model: model, context: context, selectedPost: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
#endif
			.enableDeletingWithKeyboard(of: selectedPost, confirmationDialogIsShown: $confirmationDialogIsShown)
			.confirmDeletion(ofSelected: selectedPostBinding, if: $confirmationDialogIsShown)

			.inspector(isPresented: $inspectorIsPresented) {
				if let post = selectedPost {
PostView(post: post)
				} // if let
			} // inspector
			.navigationTitle("Posts with an Unassigned Author")
		} // nav view
    } // body

	init() {
		let predicate = Post.noAuthor()
_posts = Query(filter: predicate)
	} // init
}// view

extension AuthorlessPosts {
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
