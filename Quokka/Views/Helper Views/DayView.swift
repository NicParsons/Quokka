import SwiftUI
import SwiftData

struct DayView: View {
	@Environment(Model.self) private var model
	let date: Date
	@Query private var posts: [Post]
	@Binding var selectedPost: Post?

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
    } // body
} // view
