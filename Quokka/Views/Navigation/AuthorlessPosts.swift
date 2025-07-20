import SwiftUI
import SwiftData

struct AuthorlessPosts: View {
	@Query private var posts: [Post]
	@State private var selectedPost: Post?
	@State private var inspectorIsPresented = true

    var body: some View {
		NavigationView {
			List(posts, selection: $selectedPost) { post in
				PostCapsuleView(post: post)
			} // list
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
