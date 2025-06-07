import SwiftUI

struct StopPlayingButton: View {
	@Environment(Model.self) private var model
    var body: some View {
		Button(action: {
			model.stopPlaying()
		}) {
			Label("Stop", systemImage: "stop.circle")
		} // button
		.foregroundColor(.red)
		.disabled(!model.isPlaying)
		.keyboardShortcut(".", modifiers: [.command])
    } // body
} // View
