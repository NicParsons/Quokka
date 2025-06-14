import SwiftUI
import SwiftData

struct NewUserView: View {
	@Environment(SessionManager.self) private var session
	@Environment(\.modelContext) private var modelContext
	// get all users for uniqueness check
	@Query private var existingUsers: [User]
	@State private var name = ""
	@State private var errorMessages: [String] = []
	@Binding var done: Bool
	@FocusState private var focusedField: Bool
	@State private var user: User? = nil
	let automaticallyLogIn: Bool
	let title: String = "Who are you?"

	var body: some View {
		NavigationStack {
			Form {
				// choose from an existing user (if any)
				if !existingUsers.isEmpty {
					Section(header: Text("Existing Authors")) {
						UserPicker(selectedUser: $user, title: "Authors", pickerStyle: .menu)
					} // section
				} // end if

				// or create a new one
				Section(header: Text("Create New Author")) {
					TextField("Name", text: $name)
						.focused($focusedField)
					#if os(iOS)
						.autocapitalization(.words)
						.textContentType(.name) // or .username
	  .submitLabel(.done)
	  .onSubmit {
		  focusedField = false // dismiss keyboard
		  saveUser()
	  } // on submit
					#endif
				} // section

				if !errorMessages.isEmpty {
					Section {
						ForEach(errorMessages, id: \.self) { errorMessage in
							Text("• \(errorMessage)")
								.font(.callout)
								.foregroundColor(.red)
						} // ForEach
					} // section
				} // end if
			} // form
			.padding()
			.frame(idealWidth: 250, maxWidth: 450)
			.navigationTitle(title)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") {
						if let user = user {
							session.login(as: user)
							done = true
						} else {
							saveUser()
						} // if let
					} // button
					.disabled(name.isEmpty && user == nil)
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
		guard nameIsValid() else {
return
		}

		let newUser = User(name: validatedName())
		modelContext.insert(newUser)

		do {
			try modelContext.save()
			if automaticallyLogIn { session.login(as: newUser) }
			done = true
		} catch {
			errorMessages.append("Could not create new author: \(error.localizedDescription)")
		} // do try catch
	} // func

	private func validatedName() -> String {
		return name.trimmingCharacters(in: .whitespacesAndNewlines)
	} // func

	func nameIsValid() -> Bool {
		errorMessages.removeAll()
		let trimmedName = validatedName()

		guard !trimmedName.isEmpty else {
			errorMessages.append("An author name cannot be blank.")
			return false
		}

		let nameExists = existingUsers.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
		guard !nameExists else {
			errorMessages.append("An author with this name already exists.")
			return false
		}

		guard trimmedName.count > 1 else {
			errorMessages.append("An author name must have more than one character.")
			return false
		}

		return true
	} // func
} // view
