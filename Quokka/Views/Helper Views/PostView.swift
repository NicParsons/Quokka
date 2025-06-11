import SwiftUI

struct PostView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Bindable var post: Post
@State private var duration = 0

	var body: some View {
		NavigationStack {
			VStack {
				UserPicker(selectedUser: $post.author, title: "Author", pickerStyle: .menu)
				DatePicker("Date",
						   selection: $post.date,
						   displayedComponents: [.date, .hourAndMinute])
				.datePickerStyle(.compact)

				Spacer()

				if let recording = post.recording { NowPlayingView(recording: recording) }
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
		} // Nav Stack
		.navigationTitle(post.description.capitalizingFirstLetter())
		.toolbar {
			if let recording = post.recording {
				ToolbarItem(placement: .primaryAction) {
					ShareButton(recording: recording)
				} // toolbar item
			} // if let
		} // toolbar
		.onAppear {
			// not needed on macOS due to better keyboard navigation
			#if os(iOS)
			if let recording = post.recording { model.startPlaying(recording, context: context) }
			#endif
			if let recording = post.recording {
				Task {
					await duration = recording.duration()
				} // Task
			} // if let
		} // on appear
		#if os(iOS)
		.onDisappear {
			if model.isPlaying(post.recording.fileURL) { model.pause(context) }
		} // on disappear
		#endif
	} // body
} // view
