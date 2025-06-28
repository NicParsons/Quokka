import SwiftUI

struct TodayView: View {
	@Binding var selectedPost: Post?
	@State private var presented: Bool = false

    var body: some View {
        DayView(date: Date(), selectedPost: $selectedPost)
			.inspector(isPresented: $presented) {
				if let post = selectedPost {
					PostView(post: post)
				} // if let
			} // inspector
    } // body
} // view
