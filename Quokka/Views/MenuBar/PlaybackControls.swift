import SwiftUI

struct PlaybackControlsMenu: Commands {
	@State private var model = Model()
	@FocusedValue(\.post) private var selectedPost: Post??

    var body: some Commands {
		CommandMenu("Controls") {
			if let unwrappedPost = selectedPost, let post = unwrappedPost {
				PlayPauseButton(recording: post.recording)
					.environment(model)
				.keyboardShortcut(.return, modifiers: [])
			} else {
				PlayPauseButton(recording: nil)
					.keyboardShortcut(.return, modifiers: [])
			}
			RecordOnlyButton()
				.environment(model)
				.keyboardShortcut("r", modifiers: [.command])
			StopRecordingButton()
				.environment(model)
				.keyboardShortcut(".", modifiers: [.command])
		} // CommandMenu
    } // body
} // Commandds
