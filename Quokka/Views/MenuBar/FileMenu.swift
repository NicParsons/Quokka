import SwiftUI

struct FileMenu: Commands {
@State private var model = Model()
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
		} // command group
	} // body
} // Commands struct
