import SwiftUI
import SwiftData

struct ManageUsersView: View {
	@Environment(\.modelContext) private var context
	@Query private var users: [User]
	@Query private var posts: [Post]
	@State private var showAlert = false
	@State private var currentError: Error?

    var body: some View {
		List(users) { user in
			UserEditView(user: user, title: "Edit \(user.name)")
				.onChange(of: user.name) { oldName, newName in
					print("Changed \(oldName) to \(newName).")
					do {
						try context.save()
						print("Changes saved.")
					} catch {
						currentError = error
						showAlert = true
					} // do try catch
				} // on change
		} // list
		.alert("Error Saving Changes", isPresented: $showAlert) {
			Button("Whatever") {
				currentError = nil
			} // button
		} message: {
				Text(currentError?.localizedDescription ?? "All good.")
		} // alert
    } // body
} // view
