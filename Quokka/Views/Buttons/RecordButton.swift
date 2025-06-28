import AVFoundation
import SwiftData
import SwiftUI

struct RecordButton: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Environment(SessionManager.self) private var session
	@State private var alertIsPresent = false

    var body: some View {
			Button(action: { record() }) {
					if model.isRecording {
						Label("Stop Recording", systemImage: "stop.circle")
							.frame(width: 100, height: 50, alignment: .center)
							.background(Color.red)
							.foregroundColor(.white)
							.cornerRadius(8)
					} else {
Label("Record", systemImage: "record.circle")
							.frame(width: 100, height: 50, alignment: .center)
							.background(Color.blue)
							.foregroundColor(.white)
							.cornerRadius(8)
					} // end if
			} // Button
			.accessibilityAddTraits(.startsMediaSession)
	.alert("Please grant the app access to your microphone",
		   isPresented: $alertIsPresent) {
		Button("OK", action: { print("The user dismissed the custom alert asking them to grant access to the microphone.") })
	} message: {
		Text("You need to allow Quokka to access your microphone before it can record voice messages or diary entries.")
		// conditionally show instructions depending on what platform/os
	} // alert
    } // body

	func record() {
		guard let user = session.user else { return }
		if model.isRecording {
			model.stopRecording(forAuthor: user, context: context)
		} else {
		switch AVCaptureDevice.authorizationStatus(for: .audio) {
		case .authorized:
			self.model.startRecording(context: context)
		case .notDetermined:
			print("About to prompt for access to the microphone.")
			AVCaptureDevice.requestAccess(for: .audio) { granted in
				if granted {
					self.model.startRecording(context: context)
				} else {
					print("The user denied access to the microphone.")
				} // end if access granted
			} // completion handler
		case .denied:
			print("No microphone access.")
alertIsPresent = true
		default:
			print("No microphone access.")
			alertIsPresent = true
		} // switch
		} // end if recording
	} // func
} // View
