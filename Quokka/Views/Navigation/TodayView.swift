import SwiftUI

struct TodayView: View {
	@Binding var selectedPost: Post?

    var body: some View {
        DayView(date: Date(), selectedPost: $selectedPost)
    }
}
