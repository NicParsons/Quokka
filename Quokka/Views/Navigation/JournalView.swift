import SwiftUI
import SwiftData

struct JournalView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Environment(SessionManager.self) private var session
	@Binding var selectedPost: Post?
	@State private var confirmationDialogIsShown = false

	var body: some View {
		NavigationSplitView {
			CalendarList(author: session.user, selectedPost: $selectedPost)
		} detail: {
			if let post = selectedPost {
				PostView(post: post)
			} // if let
		}// NavigationView
		.navigationTitle(Text("Your Audio Journal"))
		.toolbar {
#if os(iOS)
			ToolbarItem(placement: .navigationBarTrailing) {
				EditButton()
			} // ToolbarItem
#endif
		} // Toolbar
	} // body
} // View
