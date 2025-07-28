import SwiftUI
import SwiftData

struct DayView: View {
	@Environment(Model.self) private var model
	let date: Date
	@Query private var posts: [Post]
	@Binding var selectedPost: Post?
	@SceneStorage("selectedPostIDDayView") private var selectedPostID: Post.ID?

    var body: some View {
		NavigationView {
		VStack {
			PostList(date: date, selectedPost: $selectedPost)

			Spacer()

			if model.recordingStatus == .isNotRecording {
				HStack {
					RecordButton()
					Spacer()
					ImportButton()
				} // HStack

			} else {
RecordingProgressView()
			} // end if
		} // VStack
		} // Navigation View
		.navigationTitle(Text(date.stringWithRelativeFormatting()))

		.onAppear {
			if let postID = selectedPostID {
				print("selectedPostID in DayView = \(postID).")
				selectedPost = posts[postID]
				print("selectedPost in DayView is \(selectedPost?.description ?? "nil").")
			} // end if
		} // on appear

		.onChange(of: selectedPost) { (oldValue: Post?, newValue: Post?) in
			print("Changed selectedPost in DayView to \(newValue?.description ?? "nil").")
			selectedPostID = newValue?.id
			print("selectedPostID in DayView = \(selectedPostID.debugDescription).")
		} // on change
    } // body
} // view
