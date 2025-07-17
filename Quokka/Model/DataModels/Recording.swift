import AVFoundation
import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct Recording: Identifiable, Codable {
	let id: UUID
		var fileURL: URL
	var duration: TimeInterval = 0
	var date = Date.now

		var creationDate: Date {
				if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) as [FileAttributeKey: Any],
					let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
					return creationDate
				} else {
					return date
				} // end if
			} // end creationDate

	static func creationDate(for url: URL) -> Date {
		print("Getting creation date for \(url).")
		if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) as [FileAttributeKey: Any],
			let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
			return creationDate
		} else {
			return Date.now
		} // end if
	} // func

		var playbackPosition: TimeInterval = 0

		mutating func updatePlaybackPosition(to time: TimeInterval) {
	playbackPosition = time
			print("Updated playback position to \(time).")
		}

		var timeStamp: String {
			date.formatted(date: .omitted, time: .shortened)
		}

		var fileName: String {
			fileURL.lastPathComponent
		}

		var description: String {
			return "audio recording for \(date.formatted(date: .abbreviated, time: .omitted)) at \(date.formatted(date: .omitted, time: .shortened))"
		}

		var shortDescription: String {
			return "recording at \(timeStamp)"
		}

		func updatedDuration() async -> TimeInterval {
			var seconds: TimeInterval
			let audioAsset = AVURLAsset(url: fileURL)
			do {
				let CMTimeDuration = try await audioAsset.load(.duration)
				seconds = CMTimeDuration.seconds
			} catch {
				print(error)
				seconds = 0
			}
			return seconds
		} // func

	mutating func updateDuration() async {
duration = await updatedDuration()
	}

		func download() throws -> Bool {
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

		var statusIndicator: ModifiedContent<Image, AccessibilityAttachmentModifier> {
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

	static var errorIndicator: ModifiedContent<Image, AccessibilityAttachmentModifier> {
		Image(systemName: "exclamationmark.icloud").accessibilityLabel("Error")
	}

		enum DownloadStatus: String, Hashable {
	case downloaded, downloading, remote, error, unknown
		}

	init(id: UUID = UUID(), fileURL: URL, date: Date = Date.now, duration: TimeInterval = 0, playbackPosition: TimeInterval = 0) {
		self.id = id
		self.fileURL = fileURL
		self.duration = duration
		self.date = date
		self.playbackPosition = playbackPosition
	} // init
	 } // Recording class

	extension Recording: Transferable {
		static var transferRepresentation: some TransferRepresentation {
			FileRepresentation(contentType: .mpeg4Audio) { recording in
				SentTransferredFile(recording.fileURL)
			} importing: { received in
				let _ = try Model().importRecording(received.file.absoluteURL)
				return Self.init(fileURL: received.file.absoluteURL)
			} // FileRepresentation
			ProxyRepresentation { recording in
				recording.fileURL
			}
		}
	} // extension

	extension UTType {
		static var quokkaRecording: UTType = UTType(exportedAs: "app.openbooks.quokka.recording")
		static var quokkaPost: UTType = UTType(exportedAs: "app.openbooks.quokka.post")
	}

extension Recording {
	static func predicate(_ url: URL) -> Predicate<Recording> {
		return #Predicate<Recording> { recording in
			recording.fileURL == url
		}
	} // func
} // extension


extension Recording: Equatable {
	static func == (lhs: Recording, rhs: Recording) -> Bool {
		return lhs.fileURL == rhs.fileURL
	}
}
