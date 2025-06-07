import Foundation
import SwiftData

@Model
final class User: Identifiable {
var name: String
	@Relationship
	var posts: [Post]

	init(name: String, posts: [Post] = [Post]()) {
		self.name = name
		self.posts = posts
	}
}
