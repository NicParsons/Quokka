import SwiftUI

struct PostView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Bindable var post: Post

	var body: some View {
			VStack {
				Text(post.description.capitalizingFirstLetter())
					.font(.headline)
					.accessibilityHeading(.h1)

				UserPicker(selectedUser: $post.author, title: "Author", pickerStyle: .menu)

				DatePicker("Date",
						   selection: $post.date,
						   displayedComponents: [.date, .hourAndMinute])
				.datePickerStyle(.compact)

				PlayPauseButton(recording: post.recording)
			} // VStack
			.padding()
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.blue.opacity(0.1))
			.gesture(
// but VO doesn't recognise it yet
				DragGesture(minimumDistance: 30)
					.onEnded { value in
						if value.translation.height < -50 {
							print("Swiped up.")
							if let recording = post.recording { model.startPlaying(recording, context: context) }
						} else if value.translation.height > 50 {
							print("Swiped down.")
							model.pause(context)
						} // end if
					} // ended
			) // Gesture

		.toolbar {
			// currently implementation of ShareButton only uses Transferrable conformance of Recording or passes the post.recording.fileURL directly
			// but Post's implementation of Transferrable conformance force unwraps post.recording, so to be safe let's not show ShareButton if there is no recording
			if let _ = post.recording {
				ToolbarItem(placement: .primaryAction) {
					ShareButton(post: post)
				} // toolbar item
			} // if let
		} // toolbar
		.onAppear {
			if let recording = post.recording {
				// not needed on macOS due to better keyboard navigation
#if os(iOS)
				model.startPlaying(recording, context: context)
#endif
				Task {
					// safe to unwrap
					await post.recording!.duration = model.updatedDuration(for: recording.fileName)
				} // Task
			} // if let
		} // on appear
		#if os(iOS)
		.onDisappear {
			if model.isPlaying(post.recording?.fileName) { model.pause(context) }
		} // on disappear
		#endif
	} // body
} // view
