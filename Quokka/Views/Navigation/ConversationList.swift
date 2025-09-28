import SwiftUI
import SwiftData

struct ConversationList: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Environment(SessionManager.self) private var session
	@SceneStorage("selectedConversation") private var selectedUserID: User.ID?
	@State var selectedPostID: Post.ID? = nil
	@Query private var users: [User]

	var body: some View {
		NavigationView {
			HStack {
				List(users, selection: $selectedUserID) { user in
					Text(user.name.capitalized)
				} // list
				.listStyle(.sidebar)

				CalendarList(author: selectedUser, selectedPostID: $selectedPostID)
			} // HStack
			.padding()
		} // nav view
		.navigationTitle(navigationTitle)
	} // body
} // view

extension ConversationList {
	var selectedUser: User? {
		users.first(where: { $0.id == selectedUserID } )
	}

	var navigationTitle: String {
		if let user = selectedUser {
			return "Conversation with \(user.name)"
		} else {
			return "Conversations"
		} // if let
	} // var
} // extension
