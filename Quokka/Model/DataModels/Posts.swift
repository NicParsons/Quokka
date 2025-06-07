import Foundation
import SwiftData

@Model
final class Post {
	var date = Date.now
	var creationDate = Date.now
	@Relationship(inverse: \User.posts)
	var author: User
	var recording: Recording
var listens = 0

	init(date: Date = Date.now, creationDate: Date = Date.now, author: User, recording: Recording, listens: Int = 0) {
		self.date = date
		self.creationDate = creationDate
		self.author = author
		self.recording = recording
		self.listens = listens
	}
}

extension Array where Element: Post {
	subscript(id: Post.ID) -> Post? {
		first { $0.id == id }
	} // subscript
} // Array extension

extension Post {
	var description: String {
		return "diary entry from \(author.name) for \(date.formatted(date: .abbreviated, time: .omitted)) at \(date.formatted(date: .omitted, time: .shortened))"
	}

	var shortDescription: String {
		return "post by \(author.name) at \(timeStamp)"
	}

	var timeStamp: String {
		date.formatted(date: .omitted, time: .shortened)
	}

	static func predicate(
		authorID: User.ID? = nil,
		date: Date = .now
	) -> Predicate<Post> {
		let calendar = Calendar.autoupdatingCurrent
		let start = calendar.startOfDay(for: date)
		let end = calendar.date(byAdding: .init(day: 1), to: start) ?? start

		if let authorID {
			return #Predicate<Post> { post in
				post.author.id == authorID &&
				post.date >= start &&
				post.date <= end
			} // predicate
		} else {
			return #Predicate<Post> { post in
				post.date >= start &&
				post.date <= end
			}
		} // end if let
	} // func
} // Post extension

extension Post: Identifiable {}
