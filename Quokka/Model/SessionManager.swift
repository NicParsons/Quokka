import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class SessionManager {
	// ❌ Removed @AppStorage
	var username: String? {
		get { UserDefaults.standard.string(forKey: "username") }
		set { UserDefaults.standard.set(newValue, forKey: "username") }
	}

	var user: User?

	func createAccount(for newUser: User) {
		username = newUser.name
		user = newUser
	}

	func login(context: ModelContext) throws {
		if let username = self.username {
			let descriptor = FetchDescriptor<User>(predicate: User.predicate(name: username))
			self.user = try context.fetch(descriptor).first
		} // end if
	} // func

	init(user: User? = nil) {
		self.user = user
	}
}
