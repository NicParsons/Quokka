import SwiftData
import SwiftUI

extension View {
	@ViewBuilder func addDiaryEntryVOActions(model: Model, context: ModelContext, selectedPost: Post?, confirmationDialogIsShown: Binding<Bool>) -> some View {
		if let post = selectedPost, let recording = post.recording {
				let isPlaying = model.isPlaying(recording.fileURL)
		self
.accessibilityAction(named: Text(isPlaying ? "Pause" : "Play")) {
if isPlaying {
model.pause(context)
} else {
	model.startPlaying(recording, context: context)
} // end if
} // end action
.accessibilityAction(named: Text("Delete")) {
	confirmationDialogIsShown.wrappedValue = true
}
			} else {
				self
			}
	} // func
} // extension
