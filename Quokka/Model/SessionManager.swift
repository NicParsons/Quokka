import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class SessionManager {
	// ❌ Removed @AppStorage and UserDefaults in favour of iCloud key value storage
	private let cloud = NSUbiquitousKeyValueStore.default
	private let usernameKey = "username"

	private var username: String? {
		get {
			cloud.string(forKey: usernameKey)
		}
		set {
			cloud.set(newValue, forKey: usernameKey)
			cloud.synchronize()      // push change to iCloud asap
		}
	}

	var user: User?

	func login(as newUser: User) {
		username = newUser.name
		user = newUser
	}

	func login(_ context: ModelContext) throws {
		if let username = self.username {
			let descriptor = FetchDescriptor<User>(predicate: User.predicate(name: username))
			self.user = try context.fetch(descriptor).first
		} // end if
	} // func

	init() {
		// Observe remote changes:
		NotificationCenter.default.addObserver(
			forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
			object: cloud,
			queue: .main
		) { [weak self] _ in
			// When another device changes “username,”
			// this will fire
			guard let self = self else { return }
			// Always synchronize first
			self.cloud.synchronize()

			// The notification’s userInfo can tell you which keys changed,
			// but if it’s just one key it’s simplest to read it directly:
			let new = self.cloud.string(forKey: self.usernameKey)
			// If it’s actually different, update your property
			if new != self.username {
				self.username = new
				// —> Here you can fire your own delegate, post another Notification,
				//     or call a completion handler so your app logic knows the username moved.
			} // if changed
		} // notification

		// Kick off an initial sync
		cloud.synchronize()
	} // init
} // class
