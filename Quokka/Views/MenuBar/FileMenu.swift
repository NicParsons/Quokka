import SwiftUI

struct FileMenu: Commands {
	let model: Model
	@FocusedValue(\.post) private var selectedPost: Post??
	var body: some Commands {
		CommandGroup(after: .newItem) {
			ImportButton()
				.environment(model)
			#if os(macOS)
			if let unwrappedPost = selectedPost, let post = unwrappedPost, let recording = post.recording {
				ExportButton(recordingURL: recording.fileURL)
					.environment(model)
				.keyboardShortcut("e", modifiers: [.command])
			} else {
				ExportButton(recordingURL: nil)
					.environment(model)
			} // if let
			#endif

			//TODO: Hide the conditional logic inside the button's action and disable the button if all conditions are not met.
			if let unwrappedPost = selectedPost, let post = unwrappedPost, let _ = post.recording {
				ShareButton(post: post)
					.environment(model)
					.keyboardShortcut("s", modifiers: [.command, .option])
			} // if let
		} // command group
	} // body
} // Commands struct
