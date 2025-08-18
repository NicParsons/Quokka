import AudioToolbox
import AVFoundation
import Combine
import Foundation
import SwiftData
import SwiftUI

@Observable
class Model: NSObject, AVAudioPlayerDelegate {
	var audioRecorder: AVAudioRecorder!
	var audioPlayer: AVAudioPlayer!
	var recordingStatus: RecordingStatus = .isNotRecording
	var isPlaying = false
	var usesICloud = true
	var iCloudEnabled = false
	var documentsDirectory: URL!
	var currentlyPlayingRecording: Recording?

	var currentlyPlayingURL: URL? {
		if let player = audioPlayer {
			return player.url
		} else {
			return nil
		} // end if
	} // variable

	var playbackRate: Float = 1.0 {
		didSet {
			audioPlayer?.rate = playbackRate
		} // didSet
	} // var

	func recordingFileURL(for fileName: String) -> URL {
let directory = recordingsDirectory()
		return directory.appendingPathComponent(fileName, conformingTo: .mpeg4Audio)
	} // func

	func isPlaying(_ url: URL?) -> Bool {
		guard let url = url else { return false }
		return isPlaying && url == currentlyPlayingURL
	}

	func isPlaying(_ fileName: String?) -> Bool {
		guard let fileName = fileName else { return false }
		let url = recordingFileURL(for: fileName)
		return isPlaying(url)
	}

	func postsSortedByDay(_ posts: [Post]) -> [CalendarDay] {
		var days = [CalendarDay]()
		for post in posts {
			if days.contains(where: { post.date.isOnTheSameDay(as: $0.date) }) {
// add it to the relevant element of days
				if let index = days.firstIndex(where: { post.date.isOnTheSameDay(as: $0.date) }) {
					days[index].posts.append(post)
					// sort posts chronologically
					days[index].posts.sort(by: { $0.date < $1.date })
				} // if it' the right day
			} else {
				// create a new day
				var newDay = CalendarDay(for: post.date)
				newDay.posts.append(post)
				days.append(newDay)
			} // end if
		} // end loop
		// sort chronologically
		return days.sorted(by: { $0.date < $1.date } )
	} // end func

	var recordingSettings = [
		AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
		   AVSampleRateKey: 48000, // Apple VoiceMemos is only 24000
		   AVNumberOfChannelsKey: 1,
		   AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
	   ]

	func startRecording(context: ModelContext) {
		if recordingStatus == .isRecording {
print("A recording is already in progress.")
return
		}

		stopPlaying(context)

		print("Preparing to start recording.")
		let fileURL = newFileURL()

		do {
audioRecorder = try AVAudioRecorder(url: fileURL, settings: recordingSettings)
			// play system sound before recording starts so that sound not captured by recording
			AudioServicesPlaySystemSound(1113) // begin_record.caf
			// alternative for mac was: playSystemSound(named: "Funk", ofType: .aiff)
			// sound effect still captured on recording
			audioRecorder.record()
			DispatchQueue.main.async {
				self.recordingStatus = .isRecording
			}
			print("Recording started.")
		} catch {
			print("Could not start recording.")
			print(error)
		}
	} // func

	func pauseRecording() {
		if recordingStatus != .isRecording { return }
		guard let audioRecorder = audioRecorder else { return }
		audioRecorder.pause()
		AudioServicesPlaySystemSound(1114) // end_record.caf
		DispatchQueue.main.async {
			self.recordingStatus = .isPaused
		} // main queue
		print("Recording paused.")
	} // func

	func resumeRecording(context: ModelContext) {
		guard let audioRecorder = audioRecorder else { return }
		//TODO: stop recording playback
		if isPlaying { stopPlaying(context) }
		// play system sound before recording starts so that sound not captured by recording
		AudioServicesPlaySystemSound(1113) // begin_record.caf
		// sound effect still captured on recording
		audioRecorder.record()
		DispatchQueue.main.async {
			self.recordingStatus = .isRecording
		}
		print("Recording resumed.")
	} // func

	func stopRecording(forAuthor author: User? = nil, context: ModelContext) {
		if recordingStatus == .isNotRecording { return }
		guard let audioRecorder = audioRecorder else { return }
		let newFileURL = audioRecorder.url
		audioRecorder.stop()
		//TODO: Play appropriate system sound
		// AudioServicesPlaySystemSound(1109)
		// alternative for macOS: playSystemSound(named: "Bottle", ofType: .aiff)
		DispatchQueue.main.async {
			self.recordingStatus = .isNotRecording
		}
		print("Recording stopped.")
let _ = save(newFileURL, forAuthor: author, inContext: context)
	} // func

	func playRecording(_ url: URL, context: ModelContext) {
		// this method is to listen back to recordings in progress
		// that is, recordings that are in progress of being recorded and have not yet been saved as posts
		// they should have been saved in the recordings directory already though
		if isPlaying { stopPlaying(context) }
		DispatchQueue.main.async {
			self.currentlyPlayingRecording = nil
		}

		print("About to play \(url).")

		do {
			audioPlayer = try AVAudioPlayer(contentsOf: url)
			audioPlayer.delegate = self
			#if os(iOS)
			setupNotifications()
			#endif
					audioPlayer.play()
			print("Started playing \(url).")
				} catch {
					print("Playback failed.")
				} // do try catch
	} // func

	func startPlaying(_ recording: Recording, context: ModelContext) {
		if isPlaying { stopPlaying(context) }

		print("About to play \(recording.shortDescription).")

		let url = recordingFileURL(for: recording.fileName)

		do {
			audioPlayer = try AVAudioPlayer(contentsOf: url)
			audioPlayer.enableRate = true
			audioPlayer.rate = playbackRate
			audioPlayer.delegate = self
			#if os(iOS)
			setupNotifications()
			#endif
				audioPlayer.currentTime = recording.playbackPosition
print("Set playback position to \(audioPlayer.currentTime). The track's playback position is \(recording.playbackPosition).")
			currentlyPlayingRecording = recording
					audioPlayer.play()
			DispatchQueue.main.async {
				self.isPlaying = true
			} // main queue
			print("Started playing \(recording.shortDescription).")
				} catch {
					print("Playback failed.")
				}
	} // func

	func pause(_ context: ModelContext) {
		print("Pausing playback.")
		savePlaybackPosition(context)
		if isPlaying { audioPlayer.pause() }
		DispatchQueue.main.async {
			self.isPlaying = false
		}
print("Playback paused.")
	}

	func resumePlayback() {
		if audioPlayer == nil { return }
print("About to resume playback.")
					audioPlayer.play()
			DispatchQueue.main.async {
				self.isPlaying = true
			} // main queue
			print("Resumed playback.")
	} // func

	func stopPlaying(_ context: ModelContext) {
		print("Stopping playback.")
		savePlaybackPosition(context)
		// UI logic should mean that the stop button can only be pressed if isPlaying
		// but let's make doubly sure
		// because if nothing has yet been played the audioPlayer will be nil
		if isPlaying { audioPlayer.stop() }
		DispatchQueue.main.async {
			self.isPlaying = false
		}
		print("Playback stopped.")
	} // func

	func seekForward(_ seconds: TimeInterval = 10, context: ModelContext) {
		guard let player = audioPlayer else { return }
		let newTime = min(player.currentTime + seconds, player.duration)
		player.currentTime = newTime
		savePlaybackPosition(context)
	}

	func seekBackward(_ seconds: TimeInterval = 10, context: ModelContext) {
		guard let player = audioPlayer else { return }
		let newTime = max(player.currentTime - seconds, 0)
		player.currentTime = newTime
		savePlaybackPosition(context)
	}

	func setPlaybackPosition(to time: TimeInterval, context: ModelContext) {
		guard let player = audioPlayer else { return }
		player.currentTime = time
		savePlaybackPosition(context)
	}

	func savePlaybackPosition(_ context: ModelContext) {
		//TODO: If using SwiftData will need to pass the Recording object to this func to update its playback position.
		print("Saving playback position.")
		guard let player = audioPlayer, let url = currentlyPlayingURL else {
			return
		}

		if let post = getPost(withRecordingFileName: url.lastPathComponent, fromContext: context), let _ = post.recording {
			// safe to unwrap post.recording
			post.recording!.updatePlaybackPosition(to: player.currentTime)
			do {
				try context.save()
				print("Updated playback position.")
			} catch {
				print("Failed to save context after updating playback position: \(error)")
			} // do try ccatch
		} else {
print("Unable to update the playback position.")
		} // end if
	} // func

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
			if flag {
				//TODO: need workaround to call savePlaybackPosition(ModelContext) without ModelContext
				DispatchQueue.main.async {
					self.isPlaying = false
				} // main queue
			} // end if
		} // func

	func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
		// depricated since iOS 8
		//TODO: figure out how to call savePlaybackPosition() without access to the ModelContext.
		DispatchQueue.main.async {
			self.isPlaying = false
		} // end if
print("System interupted playback.")
	}

	// playing and recording audio requires additional configuration on iOS
	#if os(iOS)
	func configureAudioSession() {
let session = AVAudioSession.sharedInstance()
do {
	try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP])
	try session.setMode(.default)
print("Audio session configured.")
} catch {
	print("Unable to set up audio session on iOS.")
print(error)
	fatalError("Unable to configure audio session on iOS.")
} // do try catch
	} // func

	func configureRecordingSession() {
let recordingSession = AVAudioSession.sharedInstance()
do {
	try recordingSession.setActive(true)
	print("Recording session configured.")
} catch {
	print("Unable to activate recording session on iOS.")
print(error)
} // do try catch
	}

	func setupNotifications() {
		// Get the default notification center instance.
		let nc = NotificationCenter.default
		nc.addObserver(self,
					   selector: #selector(handleInterruption),
					   name: AVAudioSession.interruptionNotification,
					   object: AVAudioSession.sharedInstance())
	}

	@objc func handleInterruption(notification: Notification) {
		guard let userInfo = notification.userInfo,
			let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
				return
		}

		// Switch over the interruption type.
		switch type {
		case .began:
			// An interruption began. Update the UI as necessary.
			DispatchQueue.main.async {
				self.isPlaying = false
			} // end if
	print("System interupted playback.")
		case .ended:
		   // An interruption ended. Resume playback, if appropriate.
			guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
			let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
			if options.contains(.shouldResume) {
				// An interruption ended. Resume playback.
resumePlayback()
			} else {
				// An interruption ended. Don't resume playback.
			}
		default: ()
		}
	}
	#endif

	func playSystemSound(named soundName: String, ofType fileType: UTType) {
		if let soundID = idForSystemSound(named: soundName, ofType: fileType) {
AudioServicesPlaySystemSound(soundID)
			print("Sound played.")
		} else {
			print("Could not get valid SystemSoundID to play.")
		}
	}

	func idForSystemSound(named soundName: String, ofType fileType: UTType) -> SystemSoundID? {
		var soundID: SystemSoundID = 0 // 1013 = recording_started, 1014 = recording_stopped
		guard let url = urlForSystemSound(named: soundName, ofType: fileType) else {
			return nil
		}
		let cfURL = url as CFURL
AudioServicesCreateSystemSoundID(cfURL, &soundID)
return soundID
	} // func

	func urlForSystemSound(named soundName: String, ofType fileType: UTType) -> URL? {
		let fileManager = FileManager.default
		do {
		let library = try fileManager.url(for: .libraryDirectory, in: .systemDomainMask, appropriateFor: nil, create: false)
			let soundsDirectory = library.appendingPathComponent("Sounds", isDirectory: true)
			let soundURL = soundsDirectory.appendingPathComponent(soundName)
			return soundURL.appendingPathExtension(for: fileType)
		} catch {
			print("Could not get url for System Library directory.")
			print(error)
return nil
		}
	} // func

	func newFileURL(forDate date: Date = Date.now, authorName: String? = nil) -> URL {
		var fileName = "Quokka post"
		if let authorName = authorName { fileName += " from \(authorName)" }
		let fileExtension = ".m4a"
		let iso8601Date = date.ISO8601Format(.init(dateSeparator: .dash, dateTimeSeparator: .space, timeSeparator: .omitted, timeZoneSeparator: .omitted, includingFractionalSeconds: false, timeZone: .autoupdatingCurrent))
		let index = iso8601Date.firstIndex(of: "+") ?? iso8601Date.endIndex
		let dateTimeStamp = iso8601Date[..<index]
		let dateStamp = dateTimeStamp.components(separatedBy: .whitespaces)[0]
		let timeStamp = dateTimeStamp.components(separatedBy: .whitespaces)[1]
		let directory = recordingsDirectory()
		let fileURL = directory.appendingPathComponent("\(dateStamp) \(fileName) at \(timeStamp)\(fileExtension)")
		print("The file URL is \(fileURL).")
		return fileURL
	}

	func recordingFileExists(withFileName fileName: String) -> Bool {
		let directory = recordingsDirectory()
		let fileURL = directory.appendingPathComponent(fileName)
		return FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false))
	}

	func contentsOfFilesAreEqualStreamed(_ url1: URL, _ url2: URL, chunkSize: Int = 4096) -> Bool {
		guard FileManager.default.fileExists(atPath: url1.path(percentEncoded: false)),
			  FileManager.default.fileExists(atPath: url2.path(percentEncoded: false)) else {
			return false
		}

		guard let handle1 = try? FileHandle(forReadingFrom: url1),
			  let handle2 = try? FileHandle(forReadingFrom: url2) else {
			return false
		}

		defer {
			try? handle1.close()
			try? handle2.close()
		}

		while true {
			let data1 = try? handle1.read(upToCount: chunkSize)
			let data2 = try? handle2.read(upToCount: chunkSize)

			if data1 != data2 {
				return false
			}

			// If both are nil or empty, we've reached EOF and they're equal
			if (data1 == nil || data1?.isEmpty == true) &&
			   (data2 == nil || data2?.isEmpty == true) {
				return true
			}
		}
	}

	// Compare two audio file URLs for likely equality based on file attributes and duration.
	func audioFilesAreLikelyEqual(_ url1: URL, _ url2: URL) -> Bool {
		let fileManager = FileManager.default

		// Check file attributes
		guard let attrs1 = try? fileManager.attributesOfItem(atPath: url1.path(percentEncoded: false)),
			  let attrs2 = try? fileManager.attributesOfItem(atPath: url2.path(percentEncoded: false)),
			  let size1 = attrs1[.size] as? NSNumber,
			  let size2 = attrs2[.size] as? NSNumber,
			  let created1 = attrs1[.creationDate] as? Date,
			  let created2 = attrs2[.creationDate] as? Date,
			  size1 == size2,
			  created1 == created2 else {
			return false
		}

		// Check duration using AVAsset
		let asset1 = AVURLAsset(url: url1) // AVAsset(url: url1)
		let asset2 = AVURLAsset(url: url2) // AVAsset(url: url2)
		// AVURLAsset.duration was depricated in macOS 15
		// should use AVURLAsset.load(.duration) instead
		// but it seems like it is an async method that throws, so it won't compile without more significant changes
		//TODO: Update depricated .duration property to use .load(.duration) instead
		let duration1 = CMTimeGetSeconds(asset1.duration)
		let duration2 = CMTimeGetSeconds(asset2.duration)

		return duration1 == duration2
	}

	func setDocumentsDirectory() {
		let fileManager = FileManager.default
		if iCloudEnabled && usesICloud {
			print("The user is signed into iCloud and has chosen to use it.")
			if let url = fileManager.url(forUbiquityContainerIdentifier: nil) {
				documentsDirectory = url.appendingPathComponent("Documents", isDirectory: true)
			} else {
print("fileManager.url(forUbiquityContainerIdentifier:) returned nil.")
				// should probably throw error or something
				documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
			} // end if we could get the ubiquity container url
		} else { // doesn't use iCloud
			print("iCloud is not enabled or the user has chosen not to use it.")
			documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
		} // end if
	} // func

	func recordingsDirectory() -> URL {
		let directory = documentsDirectory.appendingPathComponent("Audio", isDirectory: true)
		var isDirectory: ObjCBool = true
		let fileManager = FileManager.default
		if !fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
			do {
				try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
			} catch {
				print("Unable to create Quokka recordings directory.")
print(error)
				//TODO: Work out what to do if unable to create the subdirectory.
			} // end do try catch
		} // end if
		return directory
	} // func

	func delete(_ posts: [Post], fromContext context: ModelContext) {
		for post in posts {
delete(post, fromContext: context)
			} // loop
	} // func

	// Delete post and associated recording
	func delete(_ post: Post, fromContext context: ModelContext, deleteRecordingFile: Bool = true) {
		// this method needs to do 4 things
		// delete the given post from the ModelContext (delete rule will ensure associated Recording object is also deleted)
		// add logging for audit, trouble shooting and debug purposes
		// stop playback if the post's recording was playing
		// and optionally delete the recording from disk

		print("About to delete \(post.description).")
		if isPlaying(post.recording?.fileName) { self.stopPlaying(context) }

		if deleteRecordingFile { deleteRecording(post.recordingFileName) }
		context.delete(post)
		do {
			try context.save()
			print("Deleted post.")
		} catch {
			print("Failed to save context after deletion: \(error)")
		} // do try ccatch
	} // func

		func deleteRecording(_ fileName: String) {
			let url = recordingFileURL(for: fileName)
			print("About to delete the recording at \(url.path(percentEncoded: false)).")
		do {
			try FileManager.default.trashItem(at: url, resultingItemURL: nil)
			print("File deleted.")
		} catch {
			print("Could not delete recording at \(url): \(error)")
		} // do try catch
		} // func

	func importRecording(_ url: URL, forAuthor author: User? = nil, toContext context: ModelContext? = nil) throws -> Post? {
		print("Importing \(url.path(percentEncoded: false)).")
		let date = Recording.creationDate(for: url)
		let destinationURL = newFileURL(forDate: date, authorName: author?.name)
		let fileManager = FileManager.default
		do {
			let didAccess = url.startAccessingSecurityScopedResource()
			try fileManager.copyItem(at: url, to: destinationURL)
			if didAccess { url.stopAccessingSecurityScopedResource() }
		} catch {
			print("Unable to copy the imported item (\(url.path(percentEncoded: false)) to \(destinationURL.path(percentEncoded: false)): \(error.localizedDescription).")
			throw error
		}
		if let context = context {
			print("About to try save the newly imported recording at \(destinationURL.path(percentEncoded: false)).")
			return save(destinationURL, forAuthor: author, onDate: date, inContext: context)
		} else {
			print("Can't save the newly imported recording as there is no ModelContext.")
			return nil
		}
	} // func

	func export(_ fileName: String, to destination: URL) throws {
		print("Exporting \(fileName) to \(destination).")
		let url = recordingFileURL(for: fileName)
		let fileManager = FileManager.default
		let destinationURL = destination.appendingPathComponent(fileName, isDirectory: false)
		do {
			let didAccess = url.startAccessingSecurityScopedResource()
			try fileManager.copyItem(at: url, to: destinationURL)
			if didAccess { url.stopAccessingSecurityScopedResource() }
		} catch {
			print("Unable to export (\(url) to \(destination).")
			print(error)
			throw error
		}
	}

	func getICloudToken() -> (NSCoding & NSCopying & NSObjectProtocol)? {
		return FileManager.default.ubiquityIdentityToken
	}

	func userIsLoggedIntoIcloud() -> Bool {
return getICloudToken() != nil
	}

	// Save new recording and post
	func save(_ url: URL, forAuthor author: User? = nil, onDate date: Date = Date.now, inContext context: ModelContext) -> Post {
		print("Saving \(url.lastPathComponent).")
		let recording = Recording(fileName: url.lastPathComponent, date: date)
		let post = Post(date: date, author: author, recording: recording)
		context.insert(post)
		do {
			try context.save()
			print("New post and recording saved.")
		} catch {
			print("Failed to save post: \(error)")
		}

		return post
	}

	func download(_ recording: Recording) throws -> Bool {
		let fileURL = recordingFileURL(for: recording.fileName)
		var status = downloadStatus(for: recording)
		if status != .downloaded && status != .downloading {
			print("About to download \(recording.description) from \(fileURL.path(percentEncoded: false)).")
			let fileManager = FileManager.default
				do {
			try fileManager.startDownloadingUbiquitousItem(at: fileURL)
				} catch {
					print("Error downloading file.: \(error.localizedDescription)")
					throw error
				} // do try catch
			} // end if
		// update status again
		status = downloadStatus(for: recording)
		if status == .downloaded || status == .downloading {
				print("Started downloading.")
				return true
			} else {
				print("Didn't start downloading.")
				return false
			} // end if
		} // func

	func downloadStatus(for recording: Recording?) -> Recording.DownloadStatus {
		if let recording = recording {
			let url = recordingFileURL(for: recording.fileName)
			do {
				let result = try url.resourceValues(forKeys: [URLResourceKey.ubiquitousItemDownloadingStatusKey, URLResourceKey.ubiquitousItemIsDownloadingKey, URLResourceKey.ubiquitousItemDownloadRequestedKey])
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
				print("Unable to get iCloud download status of \(recording.description)")
				return .error
			} // do try catch
		} else {
			// recording == nil
			return .error
		} // if let
	} // func

	func recordingStatusIndicator(for recording: Recording?) -> ModifiedContent<Image, AccessibilityAttachmentModifier> {
		let status = downloadStatus(for: recording)
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
	} // func

	func poastREcordingStatusIndicator(for post: Post) -> ModifiedContent<Image, AccessibilityAttachmentModifier> {
		if let recording = post.recording {
			  return recordingStatusIndicator(for: recording)
		  } else {
			  return Recording.errorIndicator
		  }
	} // func

	func updatedDuration(for fileName: String) async -> TimeInterval {
		print("Getting updated duration for \(fileName).")
		let fileURL = recordingFileURL(for: fileName)
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

	func updateDuration(of recording: Recording) async {
		let duration = await updatedDuration(for: recording.fileName)
		if duration != recording.duration {
			recording.duration = duration
			print("Updated duration to \(recording.duration.formattedAsDuration()) for \(recording.description).")
		} // end if
	} // func

	func updateCurrentlyPlayingRecordingDuration() async {
		if let _ = currentlyPlayingRecording {
// safe to unwrap
			let duration = await updatedDuration(for: currentlyPlayingRecording!.fileName)
			if duration != currentlyPlayingRecording!.duration {
				currentlyPlayingRecording!.duration = duration
				print("Updated currently playing recording's duration to \(duration.formattedAsDuration()).")
			} // end if
		} // if let
	} // func

	// Fetch all posts
	func fetchAllPosts(fromContext context: ModelContext) throws -> [Post] {
print("Fetching all posts.")
		let descriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.date, order: .reverse)])
		return try context.fetch(descriptor)
	}

	func getPost(withRecordingFileName fileName: String, fromContext context: ModelContext) -> Post? {
print("Fetching the post with recording file name \(fileName).")
		let predicate = Post.predicate(byFileName: fileName)
		var descriptor = FetchDescriptor(predicate: predicate)
			descriptor.fetchLimit = 1
		do {
			print("Thread is main thread: \(Thread.isMainThread).")
			return try context.fetch(descriptor).first
		} catch {
			print("Unable to fetch the specified post: \(error.localizedDescription)")
			return nil
		} // do try catch
	} // func

	func logRecordingFileNameOfAllPosts(context: ModelContext) {
		do {
			let allPosts = try fetchAllPosts(fromContext: context)
			print("📦 Stored file names:")
			for post in allPosts {
				print("– \(post.recordingFileName)")
				post.recordingFileName = post.recording?.fileName ?? ""
			} // for loop
		} catch {
			print("Could not fetch all posts to inspect file paths: \(error)")
		}
	}

	func checkForNewlyAddedRecordings(context: ModelContext, defaultUser author: User) {
print("Checking for recordings newly added to the recordings directory.")
var posts = [Post]()

		do {
			posts = try fetchAllPosts(fromContext: context)
		} catch {
print("Unable to fetch existing posts to compare with.")
			return
		}

		let fileManager = FileManager.default
		let directory = recordingsDirectory()

		do {
		let directoryContents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
			for url in directoryContents {
				if !posts.contains(where: { $0.recording?.fileName == url.lastPathComponent && $0.recordingFileName == url.lastPathComponent }) {
					let date = Recording.creationDate(for: url)
let _ = save(url, forAuthor: author, onDate: date, inContext: context)
				} // end if
			} // end loop
		} catch {
			print("Unable to check for newly added recordings because unable to get the contents of the documents directory in the app's container.")
		} // end do try catch
	} // func

	// Remove posts whose associated recording files are missing
	func removeMissingRecordings(inContext context: ModelContext) async {
		print("Removing Posts whose recordings are missing on disk.")
		do {
			let posts = try fetchAllPosts(fromContext: context)
			for post in posts {
				if let recording = post.recording {
					if post.recordingFileName.isEmpty || recording.fileName.isEmpty {
						print("There is no recording file name for \(post.description).")
						delete(post, fromContext: context, deleteRecordingFile: false)
					} else {
						// it has a file name
						let url = recordingFileURL(for: recording.fileName)
						if !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
							print("The \(post.description) has a recording with the following file name which no longer appeares to exist: \(recording.fileName).")
							delete(post, fromContext: context)
						} // end if
					} // end if
				} else {
					print("The \(post.description) does not have any recording.")
						delete(post, fromContext: context, deleteRecordingFile: false)
				} // if let
			} // end loop
				try context.save()
		} catch {
			print("Failed to remove posts whose recordings were missing: \(error)")
		} // do try catch
	} // func

	override init() {
		super.init()
		print("Instantiating a Model instance.")
iCloudEnabled = userIsLoggedIntoIcloud()
		print("The user is \(iCloudEnabled ? "" : "not") signed into icloud.")
		setDocumentsDirectory()
		#if os(iOS)
		configureAudioSession()
		configureRecordingSession()
		#endif
	}
} // class

enum RecordingStatus {
case isRecording, isPaused, isNotRecording
}
