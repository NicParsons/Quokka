import SwiftUI
import SwiftData

struct ConversationList: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Environment(SessionManager.self) private var session
	@State private var selectedUserID: User.ID? = nil
	@State var selectedPost: Post? = nil
	@Query private var users: [User]

	var body: some View {
		NavigationView {
			HStack {
				List(users, selection: $selectedUserID) { user in
					Text(user.name.capitalized)
				} // list
				.listStyle(.sidebar)

				CalendarList(author: selectedUser, selectedPost: $selectedPost)
			} // HStack
			.padding()
		} // nav view
		.navigationTitle("Conversation with \(selectedUser?.name ?? "?")")
	} // body
} // view


extension ConversationList {
	var selectedUser: User? {
		users.first(where: { $0.id == selectedUserID } )
	}
} // extension
