import SwiftUI

struct PostView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Bindable var post: Post

	var body: some View {
		NavigationStack {
			VStack {
				UserPicker(selectedUser: $post.author, title: "Author", pickerStyle: .menu)
				DatePicker("Date",
						   selection: $post.date,
						   displayedComponents: [.date, .hourAndMinute])
				.datePickerStyle(.compact)

				Spacer()

				NowPlayingView(recording: post.recording)
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
							model.startPlaying(post.recording, context: context)
						} else if value.translation.height > 50 {
							print("Swiped down.")
							model.pause(context)
						} // end if
					} // ended
			) // Gesture
		} // Nav Stack
		.navigationTitle(post.description.capitalizingFirstLetter())
		.toolbar {
				ToolbarItem(placement: .primaryAction) {
					ShareButton(post: post)
				} // toolbar item
		} // toolbar
		.onAppear {
			// not needed on macOS due to better keyboard navigation
			#if os(iOS)
			model.startPlaying(post.recording, context: context)
			#endif
				Task {
					await post.recording.duration = post.recording.updatedDuration()
				} // Task
		} // on appear
		#if os(iOS)
		.onDisappear {
			if model.isPlaying(post.recording.fileURL) { model.pause(context) }
		} // on disappear
		#endif
	} // body
} // view
