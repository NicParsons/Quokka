import SwiftUI
import SwiftData

struct ConversationList: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Environment(SessionManager.self) private var session
	@State private var selectedUser: User? = nil
	@State var selectedPost: Post? = nil
	@Query private var users: [User]

	var body: some View {
		NavigationView {
			HStack {
				List(users, selection: $selectedUser) { user in
					Text(user.name.capitalized)
				} // list

				CalendarList(author: selectedUser, selectedPost: $selectedPost)
			} // HStack
			.padding()
		} // nav view
		.navigationTitle("Conversation with \(selectedUser?.name ?? "?")")
	} // body
} // view
