import SwiftUI
import SwiftData

struct UserPicker<style: PickerStyle>: View {
	@Binding var selectedUser: User?
	@Query(sort: \User.name) private var users: [User]
	let title: String
	let pickerStyle: style // can set to .menu, .wheel or .inline

	var body: some View {
		Picker(title, selection: $selectedUser) {
			Text("None").tag(User?.none)

			ForEach(users) { user in
				Text(user.name).tag(Optional(user))
			}
		}
		.pickerStyle(pickerStyle)
	} // body
} // view
