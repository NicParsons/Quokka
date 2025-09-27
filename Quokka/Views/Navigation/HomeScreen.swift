import SwiftUI
import SwiftData

struct HomeScreen: View {
		@Environment(Model.self) private var model
	@Environment(SessionManager.self) private var session
		@Environment(\.modelContext) private var modelContext
		@Query private var posts: [Post]
		@SceneStorage("tabSelection") private var tabSelection: String?

		var body: some View {
			TabView(selection: $tabSelection) {
				Tab("Today", systemImage: "record.circle", value: "today") {
	TodayView()
				} // today tab

				Tab("Journal", systemImage: "book.circle", value: "journal") {
JournalView()
				}

				Tab("Conversations", systemImage: "person.circle", value: "conversations") {
					ConversationList()
				}

				Tab("Unassigned Posts", systemImage: "person.slash", value: "no-authors") {
AuthorlessPosts()
				}

				#if DEBUG
				Tab("Manage Users", systemImage: "person.circle", value: "users") {
ManageUsersView()
				}

				Tab("Test ShareLink", systemImage: "square.and.arrow.up", value: "test") {
TestShareView()
				}
				#endif
			} // tab view
			.tabViewStyle(.sidebarAdaptable)

				.safeAreaInset(edge: .bottom) {
					if model.currentlyPlayingRecording != nil {
					NowPlayingView()
						.frame(maxWidth: .infinity)
				} // end if
			} // safe area inset

			.onAppear {
				Task {
					await model.removeMissingRecordings(inContext: modelContext)
					// this view is only displayed if session.user exists, but let's unrap safely anyway
					if let user = session.user { model.checkForNewlyAddedRecordings(context: modelContext, defaultUser: user) }
				} // end task
			} // on appear
			} // body
		} // view

	/* placeholder code
	 struct ContentView: View {
		 @Environment(\.model) private var model
		 @Environment(\.modelContext) private var modelContext
		 @Query private var posts: [Post]

		 var body: some View {
			 NavigationSplitView {
				 List {
					 ForEach(posts) { post in
						 NavigationLink {
	 PostCapsuleView(post: post)
						 } label: {
							 Text(post.date, format: Date.FormatStyle(date: .numeric, time: .standard))
						 }
					 }
					 .onDelete(perform: deletePosts)
				 }
	 #if os(macOS)
				 .navigationSplitViewColumnWidth(min: 180, ideal: 200)
	 #endif
				 .toolbar {
	 #if os(iOS)
					 ToolbarItem(placement: .navigationBarTrailing) {
						 EditButton()
					 }
	 #endif
					 ToolbarItem {
						 Button(action: addPost) {
							 Label("Add Post", systemImage: "plus")
						 }
					 }
				 }
			 } detail: {
				 Text("Select a Post")
			 } // body
		 } // view

		 private func addPost() {
			 withAnimation {
				 let author = User(name: "Nicholas Parsons")
				 let recording = Recording(fileURL: URL(filePath: "")!)
				 let newPost = Post(author: author, recording: recording)
				 modelContext.insert(newPost)
			 }
		 }

		 private func deletePosts(offsets: IndexSet) {
			 withAnimation {
				 for index in offsets {
					 modelContext.delete(posts[index])
				 }
			 }
		 }
	 }
	 */
