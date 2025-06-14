import CoreTransferable
import Foundation
import SwiftData
import SwiftUI

@Model
final class Post {
	var date = Date.now
	var creationDate = Date.now
	@Relationship(inverse: \User.posts)
	var author: User?
	var recording: Recording?
	var listens = 0

	var authorNameString: String {
		author?.name ?? "unknown"
}

	init(date: Date = Date.now, creationDate: Date = Date.now, author: User? = nil, recording: Recording, listens: Int = 0) {
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
		return "diary entry from \(authorNameString) for \(date.formatted(date: .abbreviated, time: .omitted)) at \(date.formatted(date: .omitted, time: .shortened))"
	}

	var shortDescription: String {
		return "post by \(authorNameString) at \(timeStamp)"
	}

	var timeStamp: String {
		date.formatted(date: .omitted, time: .shortened)
	}

	// get posts within a defined date range optionally by a specified author
	static func predicate(
		authorID: User.ID? = nil,
		date: Date = .now
	) -> Predicate<Post> {
		let calendar = Calendar.autoupdatingCurrent
		let start = calendar.startOfDay(for: date)
		let end = calendar.date(byAdding: .init(day: 1), to: start) ?? start

		if let authorID {
			return #Predicate<Post> { post in
				post.author != nil &&
				post.author!.id == authorID &&
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

	// get all posts by a specified author
	static func predicate(authorID: User.ID) -> Predicate<Post> {
		#Predicate<Post> { post in
			post.author != nil &&
			post.author!.id == authorID
		}
	} // func

	// get posts by any and all authors (omitting only posts with no author)
	static func anyAurthor() -> Predicate<Post> {
		#Predicate<Post> { post in
			post.author != nil
		}
	} // func

	// get posts that have no author
	static func noAuthor() -> Predicate<Post> {
		#Predicate<Post> { post in
			post.author == nil
		}
	} // func

// get all posts by any one of an array of authors
	/* this doesn't yet compile - fix it when it's needed
	static func predicate(authors: [User]) -> Predicate<Post> {
		#Predicate<Post> { post in
			post.author != nil &&
			// the following line is the reason it doesn't compile
			authors.contains(post.author!)
		}
	} // func
	*/

	static func predicate(byURL url: URL) -> Predicate<Post> {
		#Predicate<Post> { post in
			post.recording != nil &&
			post.recording!.fileURL == url
		} // predicate
	} // func
} // Post extension

extension Post: Identifiable {}

extension Post: Transferable {
	static var transferRepresentation: some TransferRepresentation {
		ProxyRepresentation { post in
			//TODO: Only allow sharing when post.recording exists, so safe to unwrap.
			post.recording!.fileURL
		}
	} // TransferRep
} // extension


extension Post {
	var recordingStatusIndicator: ModifiedContent<Image, AccessibilityAttachmentModifier> {
		if let recording = recording {
			return recording.statusIndicator
		} else {
			return Recording.errorIndicator
		}
	}
}
