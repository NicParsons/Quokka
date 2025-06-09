import SwiftUI
import SwiftData

struct PlayButton: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	let postID: Post.ID?
	@Query private var posts: [Post]
    var body: some View {
		Button(action: {
			if let id = postID, let post = posts[id] {
				model.startPlaying(post.recording, context: context)
			} // if let
		}) {
			Label("Play", systemImage: "play.circle")
		} // button
		.foregroundColor(.blue)
		.disabled(postID == nil)
		.keyboardShortcut(" ", modifiers: [])
    } // body
} // View
