import SwiftUI

struct TodayView: View {
	@State private var selectedPost: Post? = nil
	@State private var presented: Bool = false

    var body: some View {
        DayView(date: Date(), selectedPost: $selectedPost)

			.focusedSceneValue(\.post, selectedPost)

			.inspector(isPresented: $presented) {
				if let post = selectedPost {
					PostView(post: post)
				} // if let
			} // inspector

			.onAppear {
				if selectedPost != nil { presented = true }
			} // on appear
    } // body
} // view
