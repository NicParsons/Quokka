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
	var isRecording = false
	var isPlaying = false
	//TODO: Need to check and update this programatically.
	var usesICloud = true
	var iCloudEnabled = false
	var documentsDirectory: URL!

	var currentlyPlayingURL: URL? {
		if let player = audioPlayer {
			return player.url
		} else {
			return nil
		} // end if
	} // variable

	func isPlaying(_ url: URL?) -> Bool {
		guard let url = url else { return false }
		return isPlaying && url == currentlyPlayingURL
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

	func startRecording() {
		if isRecording {
print("A recording is already in progress.")
return
		}

		print("Preparing to start recording.")
		let filePath = newFileURL()

		do {
audioRecorder = try AVAudioRecorder(url: filePath, settings: recordingSettings)
			// play system sound before recording starts so that sound not captured by recording
			AudioServicesPlaySystemSound(1113) // begin_record.caf
			// alternative for mac was: playSystemSound(named: "Funk", ofType: .aiff)
			// sound effect still captured on recording
			audioRecorder.record()
			DispatchQueue.main.async {
				self.isRecording = true
			}
			print("Recording started.")
		} catch {
			print("Could not start recording.")
			print(error)
		}
	} // func

	func stopRecording(forAuthor author: User? = nil, context: ModelContext) {
		// should be safe to force unwrap audioRecorder as stopRecording can only be called if a recording has started
		let newFileURL = audioRecorder!.url
		audioRecorder!.stop()
		AudioServicesPlaySystemSound(1114) // end_record.caf
		// alternative for macOS: playSystemSound(named: "Bottle", ofType: .aiff)
		isRecording = false
		print("Recording stopped.")
let _ = save(newFileURL, forAuthor: author, inContext: context)
	} // func

	func startPlaying(_ recording: Recording, context: ModelContext) {
		if isPlaying { stopPlaying(context) }

		print("About to play \(recording.shortDescription).")

		do {
			audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
			audioPlayer.delegate = self
			#if os(iOS)
			setupNotifications()
			#endif
				audioPlayer.currentTime = recording.playbackPosition
print("Set playback position to \(audioPlayer.currentTime). The track's playback position is \(recording.playbackPosition).")
					audioPlayer.play()
			DispatchQueue.main.async {
				self.isPlaying = true
			} // main queue
			print("Started playing \(recording.fileURL).")
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

		if let post = getPost(withURL: url, fromContext: context) {
			post.recording.updatePlaybackPosition(to: player.currentTime)
			do {
				try context.save()
				print("Updated playback position.")
			} catch {
				print("Failed to save context after updating playback position: \(error)")
			} // do try ccatch
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
// need method to resume playback
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

	func newFileURL() -> URL {
		let fileName = "Quokka post"
		let fileExtension = ".m4a"
		let iso8601Date = Date().ISO8601Format(.init(dateSeparator: .dash, dateTimeSeparator: .space, timeSeparator: .omitted, timeZoneSeparator: .omitted, includingFractionalSeconds: false, timeZone: .autoupdatingCurrent))
		let index = iso8601Date.firstIndex(of: "+") ?? iso8601Date.endIndex
		let dateTimeStamp = iso8601Date[..<index]
		let dateStamp = dateTimeStamp.components(separatedBy: .whitespaces)[0]
		let timeStamp = dateTimeStamp.components(separatedBy: .whitespaces)[1]
		let documentPath = recordingsDirectory()
		let filePath = documentPath.appendingPathComponent("\(dateStamp) \(fileName) at \(timeStamp)\(fileExtension)")
		print("The file URL is \(filePath).")
		return filePath
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
		let subDirectory = documentsDirectory.appendingPathComponent("Audio", isDirectory: true)
		var isDirectory: ObjCBool = true
		let fileManager = FileManager.default
		if !fileManager.fileExists(atPath: subDirectory.path, isDirectory: &isDirectory) {
			do {
				try fileManager.createDirectory(at: subDirectory, withIntermediateDirectories: true)
			} catch {
				print("Unable to create Diary Entries directory.")
print(error)
				//TODO: Work out what to do if unable to create the subdirectory.
			} // end do try catch
		} // end if
		return subDirectory
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
		if isPlaying(post.recording.fileURL) { self.stopPlaying(context) }

		if deleteRecordingFile { deleteRecording(post.recording.fileURL) }
		context.delete(post)
		do {
			try context.save()
			print("Deleted post.")
		} catch {
			print("Failed to save context after deletion: \(error)")
		} // do try ccatch
	} // func

		func deleteRecording(_ url: URL?) {
			guard let url = url else { return }
			print("About to delete the recording at \(url.path()).")
		do {
			try FileManager.default.trashItem(at: url, resultingItemURL: nil)
			print("File deleted.")
		} catch {
			print("Could not delete recording at \(url): \(error)")
		} // do try catch
		} // func

	func importRecording(_ url: URL, forAuthor author: User? = nil, toContext context: ModelContext? = nil) throws -> Post? {
		let fileName = url.lastPathComponent
		let destinationURL = recordingsDirectory().appendingPathComponent(fileName, isDirectory: false)
		let fileManager = FileManager.default
		do {
			let didAccess = url.startAccessingSecurityScopedResource()
			try fileManager.copyItem(at: url, to: destinationURL)
			if didAccess { url.stopAccessingSecurityScopedResource() }
		} catch {
			print("Unable to copy the imported item (\(url) to \(destinationURL): \(error.localizedDescription).")
			throw error
		}
		if let context = context {
			return save(url, forAuthor: author, inContext: context)
		} else {
			return nil
		}
	} // func

	func export(_ url: URL, to destination: URL) throws {
		print("Exporting \(url) to \(destination).")
		let fileName = url.lastPathComponent
		let fileManager = FileManager.default
		// while we work out how to export to the actual destination
		// let destinationDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
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

	func isUserLoggedIntoIcloud() -> Bool {
return getICloudToken() != nil
	}

	// Save new recording and post
	func save(_ url: URL, forAuthor author: User? = nil, forDate date: Date = Date.now, inContext context: ModelContext) -> Post {
		print("Saving \(url).")
		let recording = Recording(fileURL: url)
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

	// Fetch all posts
	func fetchAllPosts(fromContext context: ModelContext) throws -> [Post] {
print("Fetching all posts.")
		let descriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.date, order: .reverse)])
		return try context.fetch(descriptor)
	}

	func getPost(withURL url: URL, fromContext context: ModelContext) -> Post? {
print("Fetching the post with recording url \(url).")
		let predicate = Post.predicate(byURL: url)
		var descriptor = FetchDescriptor(predicate: predicate)
			descriptor.fetchLimit = 1
		do {
			return try context.fetch(descriptor).first
		} catch {
			print("Unable to fetch the specified post: \(error.localizedDescription)")
			return nil
		} // do try catch
	} // func

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
				if !posts.contains(where: { $0.recording.fileURL == url }) {
let _ = save(url, forAuthor: author, inContext: context)
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
				if !FileManager.default.fileExists(atPath: post.recording.fileURL.path) {
					print("The recording at the following path no longer appeares to exist: \(post.recording.fileURL.path).")
						delete(post, fromContext: context)
					} // end if
			} // end loop
			try context.save()
		} catch {
			print("Failed to remove posts whose recordings were missing: \(error)")
		} // do try catch
	} // func

	override init() {
		super.init()
iCloudEnabled = isUserLoggedIntoIcloud()
		print("The user is \(iCloudEnabled ? "" : "not") signed into icloud.")
		setDocumentsDirectory()
		#if os(iOS)
		configureAudioSession()
		configureRecordingSession()
		#endif
	}
} // class
