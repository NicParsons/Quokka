import AVFoundation
import CoreTransferable
import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@Model
final class Recording: Identifiable {
	@Relationship(inverse: \Post.recording)
var post: Post?
	var fileName: String = ""
	var date = Date.now
	var duration: TimeInterval = 0
	var playbackPosition: TimeInterval = 0

	func creationDate(_ model: Model) -> Date {
		let url = model.recordingFileURL(for: fileName)
		let path = url.path(percentEncoded: false)
		if let attributes = try? FileManager.default.attributesOfItem(atPath: path) as [FileAttributeKey: Any],
					let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
					return creationDate
				} else {
					return date
				} // end if
			} // end creationDate

	static func creationDate(for url: URL) -> Date {
		print("Getting creation date for \(url).")
		if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false)) as [FileAttributeKey: Any],
			let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
			print("The creation date is \(creationDate.formatted()).")
			return creationDate
		} else {
			print("Can't get file attributes.")
			return Date.now
		} // end if
	} // func

		func updatePlaybackPosition(to time: TimeInterval) {
	playbackPosition = time
			print("Updated playback position to \(time).")
		}

		var timeStamp: String {
			date.formatted(date: .omitted, time: .shortened)
		}

		var description: String {
			return "audio recording by \(post?.authorNameString ?? "someone") for \(date.formatted(date: .abbreviated, time: .omitted)) at \(date.formatted(date: .omitted, time: .shortened))"
		}

		var shortDescription: String {
			return "recording by \(post?.authorNameString ?? "someone") at \(timeStamp)"
		}

	static var errorIndicator: ModifiedContent<Image, AccessibilityAttachmentModifier> {
		Image(systemName: "exclamationmark.icloud").accessibilityLabel("Error")
	}

		enum DownloadStatus: String, Hashable {
	case downloaded, downloading, remote, error, unknown
		}

	init(fileName: String = "", date: Date = Date.now, duration: TimeInterval = 0, playbackPosition: TimeInterval = 0) {
		self.fileName = fileName
		self.duration = duration
		self.date = date
		self.playbackPosition = playbackPosition
	} // init
	 } // Recording class

	extension Recording: Transferable {
		static var transferRepresentation: some TransferRepresentation {
			FileRepresentation(contentType: .mpeg4Audio) { recording in
				SentTransferredFile(Model().recordingFileURL(for: recording.fileName))
			} importing: { received in
				let _ = try Model().importRecording(received.file.absoluteURL)
				return Self.init(fileName: received.file.lastPathComponent)
			} // FileRepresentation
			ProxyRepresentation { recording in
				Model().recordingFileURL(for: recording.fileName)
			}
		}
	} // extension

	extension UTType {
		static var quokkaRecording: UTType = UTType(exportedAs: "app.openbooks.quokka.recording")
		static var quokkaPost: UTType = UTType(exportedAs: "app.openbooks.quokka.post")
	}

extension Recording {
	static func predicate(_ fileName: String) -> Predicate<Recording> {
		return #Predicate<Recording> { recording in
			recording.fileName == fileName
		}
	} // func
} // extension

extension Recording: Equatable {
	static func == (lhs: Recording, rhs: Recording) -> Bool {
		return lhs.fileName == rhs.fileName
	}
}
