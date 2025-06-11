import SwiftUI
import SwiftData

struct PlayButton: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	let recording: Recording?

    var body: some View {
		Button(action: {
			if let recording = recording {
				model.startPlaying(recording, context: context)
			} // if let
		}) {
			Label("Play", systemImage: "play.circle")
		} // button
		.foregroundColor(.blue)
		.disabled(recording == nil)
		.keyboardShortcut(" ", modifiers: [])
    } // body
} // View
