import SwiftUI
import SwiftData

struct DayView: View {
	@Environment(Model.self) private var model
	let date: Date
	@State private var overlayText = ""
	@Query private var posts: [Post]
	@Binding var selectedPost: Post?
	@SceneStorage("selectedPostIDDayView") private var selectedPostID: Post.ID?

    var body: some View {
		NavigationView {
		VStack {
			PostList(posts: posts, overlayText: overlayText, selectedPost: $selectedPost)

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

			if overlayText.isEmpty { overlayText = "You haven't recorded a diary entry for \(date.stringWithRelativeFormatting().lowercased()) yet. Hit the “Record” button to get started." }
		} // on appear

		.onChange(of: selectedPost) { (oldValue: Post?, newValue: Post?) in
			print("Changed selectedPost in DayView to \(newValue?.description ?? "nil").")
			selectedPostID = newValue?.id
			print("selectedPostID in DayView = \(selectedPostID.debugDescription).")
		} // on change
    } // body

	init(
		date: Date,
		selectedPost: Binding<Post?>,
		sortOrder: SortOrder = .forward
	) {
		self.date = date
		_selectedPost = selectedPost
		let predicate = Post.predicate(date: date)
		_posts = Query(filter: predicate, sort: \.date, order: sortOrder)
	}
} // view
