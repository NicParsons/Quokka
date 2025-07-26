import SwiftUI

struct PlaybackControlsMenu: Commands {
	let model: Model
	@FocusedValue(\.post) private var selectedPost: Post??
	var session: SessionManager

    var body: some Commands {
		CommandMenu("Controls") {
			if let unwrappedPost = selectedPost, let post = unwrappedPost {
				PlayPauseButton(recording: post.recording)
					.environment(model)
				.keyboardShortcut(.return, modifiers: [])
			} else {
				PlayPauseButton(recording: nil)
					.environment(model)
					.keyboardShortcut(.return, modifiers: [])
			}
			if let user = session.user {
				RecordOnlyButton()
					.environment(model)
					.keyboardShortcut("r", modifiers: [.command])
				StopRecordingButton(author: user)
					.environment(model)
					.keyboardShortcut(".", modifiers: [.command])
			} // if let
		} // CommandMenu
    } // body
} // Commandds
