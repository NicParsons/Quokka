import SwiftUI
import SwiftData

struct JournalView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Environment(SessionManager.self) private var session
	@State var selectedPost: Post? = nil
	@State private var confirmationDialogIsShown = false
	@State private var presented: Bool = false

	var body: some View {
		NavigationView {
			CalendarList(author: session.user, selectedPost: $selectedPost)
				.inspector(isPresented: $presented) {
					if let post = selectedPost {
						PostView(post: post)
					} // if let
				} // inspect
		}// NavigationView
		.navigationTitle(Text("Your Audio Journal"))
		.toolbar {
#if os(iOS)
			ToolbarItem(placement: .navigationBarTrailing) {
				EditButton()
			} // ToolbarItem
#endif
		} // Toolbar

		.focusedSceneValue(\.post, selectedPost)

		.onAppear {
			if selectedPost != nil { presented = true }
		} // on appear
	} // body
} // View
