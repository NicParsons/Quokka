import SwiftUI
import SwiftData

struct ConversationList: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Environment(SessionManager.self) private var session
	@SceneStorage("selectedConversation") private var selectedUserID: User.ID?
	@State var selectedPostID: Post.ID? = nil
	@State var presented = true
	@Query private var users: [User]

	var body: some View {
		NavigationView {
			HStack {
				List(users, selection: $selectedUserID) { user in
					Text(user.name.capitalized)
				} // list
				.listStyle(.sidebar)

				CalendarList(author: selectedUser, selectedPostID: $selectedPostID)

					.inspector(isPresented: $presented) {
						if let post = selectedPost {
							PostView(post: post)
						} // if let
					} // inspect
			} // HStack
			.padding()
		} // nav view
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				InspectorButton(presented: $presented)
			}
		}
		.navigationTitle(navigationTitle)

		#if debug
		.onChange(of: selectedUserID) {
			print("Sidebar selection changed to \(selectedUser?.name ?? "nil").")
		}

		.onAppear {
			print("\(selectedUser?.name) is selected in the conversation list sidebar with ID \(selectedUserID).")
		}
		#endif
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

	var selectedPost: Post? {
		guard let postID = selectedPostID else { return nil }
		do {
			var descriptor = FetchDescriptor<Post>(
				predicate: #Predicate { $0.id == postID }
			)
			descriptor.fetchLimit = 1
			let results = try context.fetch(descriptor)
			return results.first
		} catch {
			#if DEBUG
			print("Failed to fetch Post with id: \(postID). Error: \(error)")
			#endif
			return nil
		}
	} // var
} // extension



struct InspectorButton: View {
	@Binding var presented: Bool

	var body: some View {
Toggle(
	isOn: $presented) {
		if presented {
Label("Hide Inspector", systemImage: "eye")
		} else {
Label("Show Inspector", systemImage: "eye.fill")
		} // end if
	} // end label
	} // body
} // View
