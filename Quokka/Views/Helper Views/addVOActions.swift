import SwiftData
import SwiftUI

extension View {
	@ViewBuilder func addDiaryEntryVOActions(model: Model, context: ModelContext, selectedPost: Post?, confirmationDialogIsShown: Binding<Bool>) -> some View {
		if let post = selectedPost {
			let isPlaying = model.isPlaying(post.recording.fileURL)
		self
.accessibilityAction(named: Text(isPlaying ? "Pause" : "Play")) {
if isPlaying {
model.pause(context)
} else {
	model.startPlaying(post.recording, context: context)
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
