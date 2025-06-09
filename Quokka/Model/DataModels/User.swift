import Foundation
import SwiftData

@Model
final class User: Identifiable {
var name: String
	@Relationship(deleteRule: .cascade)
	var posts: [Post]

	init(name: String, posts: [Post] = [Post]()) {
		self.name = name
		self.posts = posts
	}
}

extension User {
	static func predicate(name: String) -> Predicate<User> {
		return #Predicate<User> { user in
			user.name == name
		} // predicate
	} // func
} // extension
