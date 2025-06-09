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
	@FocusState private var focusedField: Bool
	let automaticallyLogIn: Bool

	var body: some View {
		NavigationStack {
			Form {
				Section(header: Text("User Name")) {
					TextField("Name", text: $name)
						.focused($focusedField)
					#if os(iOS)
						.autocapitalization(.words)
						.textContentType(.name) // or .username
	  .submitLabel(.done)
	  .onSubmit {
		  focusedField = false // dismiss keyboard
	  } // on submit
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
			.frame(maxWidth: 450)
			.navigationTitle("Create New User")
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") {
						saveUser()
					} // button
					.disabled(!nameIsValid())
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
		guard nameIsValid(withErrorReporting: true) else {
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

	func nameIsValid(withErrorReporting errorReportingEnabled: Bool = false) -> Bool {
		let trimmedName = validatedName()

		guard !trimmedName.isEmpty else {
			if errorReportingEnabled { errorMessage = "A user name cannot be blank." }
			return false
		}

		let nameExists = existingUsers.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
		guard !nameExists else {
			if errorReportingEnabled { errorMessage = "A user with this name already exists." }
			return false
		}

		guard trimmedName.count > 1 else {
			if errorReportingEnabled { errorMessage = "A user name must have more than one character." }
			return false
		}

		return true
	} // func
} // view
