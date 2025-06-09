import SwiftUI

struct PlayPauseButton: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	let recording: Recording?

    var body: some View {
		Button(action: {
			if let recording = recording {
				if model.isPlaying(recording.fileURL) {
					model.pause(context)
				} else if model.currentlyPlayingURL == recording.fileURL {
					model.resumePlayback()
				} else {
				model.startPlaying(recording, context: context)
				} // end if
			} // if let
		}) {
			if let recording = recording {
				if model.isPlaying(recording.fileURL) {
Label("Pause", systemImage: "pause.circle")
						.background(Color.red)
						.foregroundColor(.white)
						.cornerRadius(8)
				} else {
			Label("Play", systemImage: "play.circle")
						.background(Color.blue)
						.foregroundColor(.white)
						.cornerRadius(8)
				} // end if
			} else {
		Label("Play", systemImage: "play.circle")
					.background(Color.blue)
					.foregroundColor(.white)
					.cornerRadius(8)
			} // end if let
		} // button
		.disabled(recording == nil)
		// .keyboardShortcut(" ", modifiers: [])
    } // body
} // view
