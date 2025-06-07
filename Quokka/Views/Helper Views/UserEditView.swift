import SwiftUI

struct UserEditView: View {
	@Bindable var user: User
	let title: String

    var body: some View {
		VStack {
Text(title)
				.font(.headline)
				.accessibilityAddTraits(.isHeader)

			TextField("User name",
					  text: $user.name,
					  prompt: Text(user.name.isEmpty ? "Helly R" : user.name))
		} // VStack
		.padding()
    } // body
} // view
