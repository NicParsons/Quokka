import SwiftUI

struct StopRecordingButton: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	let author: User

	var body: some View {
			Button(
				action: {
					model.stopRecording(forAuthor: author, context: context)
				}) {
						Label("Stop Recording", systemImage: "stop.circle")
			} // Button
				.disabled(!model.isRecording)
				.foregroundColor(.red)
	} // body
} // View
