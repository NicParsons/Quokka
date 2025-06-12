import AVFoundation
import CoreTransferable
import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@Model
final class Recording {
		var fileURL: URL?
	@Relationship(inverse: \Post.recording) var post: Post?

		var creationDate: Date {
				if let url = fileURL, let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) as [FileAttributeKey: Any],
					let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
					return creationDate
				} else {
					return Date.now
				} // end if
			} // end creationDate

		var playbackPosition: TimeInterval = 0

		func updatePlaybackPosition(to time: TimeInterval) {
	playbackPosition = time
			print("Updated playback position to \(time).")
		}

		var timeStamp: String {
			creationDate.formatted(date: .omitted, time: .shortened)
		}

		var fileName: String {
			fileURL?.lastPathComponent ?? ""
		}

		var description: String {
			return "audio recording for \(creationDate.formatted(date: .abbreviated, time: .omitted)) at \(creationDate.formatted(date: .omitted, time: .shortened))"
		}

		var shortDescription: String {
			return "recording at \(timeStamp)"
		}

		func duration() async -> Int {
			guard let fileURL = fileURL else { return 0 }
			var seconds: Int
			let audioAsset = AVURLAsset(url: fileURL)
			do {
				let CMTimeDuration = try await audioAsset.load(.duration)
				seconds = Int(CMTimeDuration.seconds)
			} catch {
				print(error)
				seconds = 0
			}
			return seconds
		} // func

		func download() throws -> Bool {
			guard let fileURL = fileURL else { return false }
			if status != .downloaded && status != .downloading {
				print("About to download \(fileURL.description).")
			let fileManager = FileManager.default
				do {
			try fileManager.startDownloadingUbiquitousItem(at: fileURL)
				} catch {
					print("Error downloading file.: \(error.localizedDescription)")
					throw error
				} // do try catch
			} // end if
			if status == .downloaded || status == .downloading {
				print("Started downloading.")
				return true
			} else {
				print("Didn't start downloading.")
				return false
			}
		}

		var status: DownloadStatus {
			guard let fileURL = fileURL else { return .error }
			do {
				let result = try fileURL.resourceValues(forKeys: [URLResourceKey.ubiquitousItemDownloadingStatusKey, URLResourceKey.ubiquitousItemIsDownloadingKey, URLResourceKey.ubiquitousItemDownloadRequestedKey])
				let downloadingStatus = result.ubiquitousItemDownloadingStatus
				if downloadingStatus == URLUbiquitousItemDownloadingStatus.notDownloaded {
	// it's either downloading or remote
					if let isDownloading = result.ubiquitousItemIsDownloading, let downloadRequested = result.ubiquitousItemDownloadRequested {
						if isDownloading || downloadRequested {
						return .downloading
					} else {
						return .remote
					}
					} else {
	// couldn't get status
						return .unknown
					}
				} else {
					// it's downloaded
					return .downloaded
				}
			} catch {
				print("Unable to get iCloud download status of \(fileURL.description)")
				return .error
			} // do try catch
		} // var declaration

		var statusIndicator: some View {
			switch status {
			case .remote:
				return Image(systemName: "icloud")
					.accessibilityLabel("Download")
			case .downloading:
				return Image(systemName: "icloud.and.arrow.down")
					.accessibilityLabel("Downloading")
			case .downloaded:
				return Image(systemName: "icloud.and.arrow.down.fill")
					.accessibilityLabel("Downloaded")
			case .error:
				return Image(systemName: "exclamationmark.icloud")
					.accessibilityLabel("Error")
			case .unknown:
				return Image(systemName: "questionmark")
					.accessibilityLabel("Indeterminate")
			} // switch
		}

		enum DownloadStatus: String, Hashable {
	case downloaded, downloading, remote, error, unknown
		}

	init(fileURL: URL?, playbackPosition: TimeInterval = 0) {
		self.fileURL = fileURL
		self.playbackPosition = playbackPosition
	} // init
	 } // Recording class

	extension Recording: Transferable {
		static var transferRepresentation: some TransferRepresentation {
			FileRepresentation(contentType: .mpeg4Audio) { recording in
				if let fileURL = recording.fileURL {
					return SentTransferredFile(fileURL)
				} else {
					return SentTransferredFile(URL(fileURLWithPath: ""))
				}
			} importing: { received in
				let _ = try Model().importRecording(received.file.absoluteURL)
				return Self.init(fileURL: received.file.absoluteURL)
			}
		}
	} // extension

	extension UTType {
		static var quokkaRecording: UTType = UTType(exportedAs: "app.openbooks.quokka.recording")
		static var quokkaPost: UTType = UTType(exportedAs: "app.openbooks.quokka.post")
	}

extension Array where Element: Recording {
	subscript(id: Recording.ID) -> Recording? {
		first { $0.id == id }
	}

	subscript(url: URL) -> Recording? {
		first { $0.fileURL == url }
	}
} // Array extension

extension Recording {
	static func predicate(_ url: URL) -> Predicate<Recording> {
		return #Predicate<Recording> { recording in
			recording.fileURL == url
		}
	} // func
} // extension

extension Recording: Identifiable {}
