import SwiftUI
import SwiftData

struct NewUserView: View {
	@Environment(SessionManager.self) private var session
	@Environment(\.modelContext) private var modelContext
	// get all users for uniqueness check
	@Query private var existingUsers: [User]
	@State private var name = ""
	@State private var errorMessage: String?
	@Binding var done: Bool
	let automaticallyLogIn: Bool

	var body: some View {
		NavigationStack {
			Form {
				Section(header: Text("User Name")) {
					TextField("Name", text: $name)
					#if os(iOS)
						.autocapitalization(.words)
					#endif
				} // section

				if let errorMessage = errorMessage {
					Section {
						Text(errorMessage)
							.foregroundColor(.red)
					} // section
				} // end if
			} // form
			.padding()
			.navigationTitle("Create New User")
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") {
						saveUser()
					} // button
					.disabled(!nameIsValid)
				} // toolbar item

				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
done = true
					} // button
				} // toolbar item
			} // toolbar
		} // nav stack
	} // body

	private func saveUser() {
		guard nameIsValid else {
return
		}

		let newUser = User(name: validatedName())
		modelContext.insert(newUser)

		do {
			try modelContext.save()
			if automaticallyLogIn { session.createAccount(for: newUser) }
			done = true
		} catch {
			errorMessage = "Could not create new user: \(error.localizedDescription)"
		} // do try catch
	} // func

	private func validatedName() -> String {
		return name.trimmingCharacters(in: .whitespacesAndNewlines)
	} // func
} // view

extension NewUserView {
	var nameIsValid: Bool {
		let trimmedName = validatedName()

		guard !trimmedName.isEmpty else {
			errorMessage = "A user name cannot be blank."
			return false
		}

		let nameExists = existingUsers.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
		guard !nameExists else {
			errorMessage = "A user with this name already exists."
			return false
		}

		guard trimmedName.count > 1 else {
			errorMessage = "A user name must have more than one character."
			return false
		}

		return true
	} // var
} // extension
