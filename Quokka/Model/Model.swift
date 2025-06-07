import Foundation
import Combine
import AVFoundation
import SwiftUI
import AudioToolbox

@Observable
class Model: NSObject, AVAudioPlayerDelegate {
	var audioRecorder: AVAudioRecorder!
	var audioPlayer: AVAudioPlayer!
	var isRecording = false
	var isPlaying = false
	var recordings: [Recording] = []
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

	func isPlaying(_ url: URL) -> Bool {
		return isPlaying && audioPlayer.url == url
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

	func stopRecording() {
		// should be safe to force unwrap audioRecorder as stopRecording can only be called if a recording has started
		let newFileURL = audioRecorder!.url
		audioRecorder!.stop()
		AudioServicesPlaySystemSound(1114) // end_record.caf
		// alternative for macOS: playSystemSound(named: "Bottle", ofType: .aiff)
		isRecording = false
		print("Recording stopped.")
let _ = save(newFileURL)
	} // func

	func startPlaying(_ recording: Recording) {
		if isPlaying { stopPlaying() }

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

	func pause() {
		print("Pausing playback.")
		savePlaybackPosition()
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

	func stopPlaying() {
		print("Stopping playback.")
		savePlaybackPosition()
		// UI logic should mean that the stop button can only be pressed if isPlaying
		// but let's make doubly sure
		// because if nothing has yet been played the audioPlayer will be nil
		if isPlaying { audioPlayer.stop() }
		DispatchQueue.main.async {
			self.isPlaying = false
		}
		print("Playback stopped.")
	} // func

	func seekForward(_ seconds: TimeInterval = 10) {
		guard let player = audioPlayer else { return }
		let newTime = min(player.currentTime + seconds, player.duration)
		player.currentTime = newTime
		savePlaybackPosition()
	}

	func seekBackward(_ seconds: TimeInterval = 10) {
		guard let player = audioPlayer else { return }
		let newTime = max(player.currentTime - seconds, 0)
		player.currentTime = newTime
		savePlaybackPosition()
	}

	func setPlaybackPosition(to time: TimeInterval) {
		guard let player = audioPlayer else { return }
		player.currentTime = time
		savePlaybackPosition()
	}

	func savePlaybackPosition() {
		//TODO: If using SwiftData will need to pass the Recording object to this func to update its playback position.
		print("Saving playback position.")
		guard let player = audioPlayer, let url = currentlyPlayingURL else {
			return
		}
		if let index = recordings.firstIndex(where: { $0.fileURL == url }) {
		recordings[index].updatePlaybackPosition(to: player.currentTime)
		//TODO: ModelContext.save() after updating playback position.
		}
	}

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
			if flag {
				savePlaybackPosition()
				DispatchQueue.main.async {
					self.isPlaying = false
				} // main queue
			} // end if
		} // func

	func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
		// depricated since iOS 8
		savePlaybackPosition()
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
		let fileName = "Diary Entry"
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
		let subDirectory = documentsDirectory.appendingPathComponent("Diary Entries", isDirectory: true)
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

	func delete(_ recording: Recording) {
		let url = recording.fileURL
		delete(url)
//TODO: Save Model Context.
	}

	func delete(_ urlsToDelete: [URL]) {
			for url in urlsToDelete {
				delete(url)
			} // loop
//TODO: Save Model Context.
	} // func

	func delete(_ url: URL) {
		print("Deleting \(url).")
		do {
		   try FileManager.default.trashItem(at: url, resultingItemURL: nil)
			print("File deleted.")
			if isPlaying && audioPlayer.url == url { self.stopPlaying() }
		} catch {
			print("Could not delete \(url). The error was: \(error.localizedDescription)")
		} // do try catch
		recordings.removeAll(where: { $0.fileURL == url } )
		print("Recording removed from recordings array.")
	}

	func importRecording(_ url: URL) throws -> Recording {
		let fileName = url.lastPathComponent
		let destinationURL = recordingsDirectory().appendingPathComponent(fileName, isDirectory: false)
		let fileManager = FileManager.default
		do {
			let didAccess = url.startAccessingSecurityScopedResource()
			try fileManager.copyItem(at: url, to: destinationURL)
			if didAccess { url.stopAccessingSecurityScopedResource() }
		} catch {
			print("Unable to copy the imported item (\(url) to \(destinationURL).")
			print(error)
			throw error
		}
		let newRecording = save(destinationURL)
		return newRecording
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

	func save(_ url: URL) -> Recording {
print("Saving \(url).")
let newDiaryEntry = Recording(fileURL: url)
//TODO: Save Model Context.
		print("New diary entry recording saved.")
		return newDiaryEntry
	}

	func fetchAllRecordings() {
		removeMissingRecordings()
		print("Fetching recordings.")
		let fileManager = FileManager.default
		let directory = recordingsDirectory()
		var needToSave = false

		do {
		let directoryContents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
			for url in directoryContents {
				if !recordings.contains(where: { $0.fileURL == url }) {
				print("Fetching \(url)")
	let recording = Recording(fileURL: url)
				recordings.append(recording)
				recordings.sort(by: { $0.creationDate.compare($1.creationDate) == .orderedAscending})
					needToSave = true
				} // end if
			} // end loop
		} catch {
			print("Unable to fetch recordings because unable to get the contents of the documents directory in the app's container.")
		} // end do try catch
		//TODO: Save Model Context.
		if needToSave { print("Need to save model context.") }
	} // func

	func removeMissingRecordings() {
print("Removing missing recordings.")
		let fileManager = FileManager.default
		for recording in recordings {
			let fileExists = fileManager.fileExists(atPath: recording.fileURL.path)
			if !fileExists {
				print("The recording at the following path no longer appeares to exist: \(recording.fileURL.path).")
				recordings.removeAll(where: { $0.fileURL == recording.fileURL})
				print("Recording removed.")
			}
		}
	}

	override init() {
		super.init()
iCloudEnabled = isUserLoggedIntoIcloud()
		print("The user is \(iCloudEnabled ? "" : "not") signed into icloud.")
		setDocumentsDirectory()
		fetchAllRecordings()
		#if os(iOS)
		configureAudioSession()
		configureRecordingSession()
		#endif
	}
} // class
