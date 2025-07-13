import SwiftUI

struct RecordingProgressView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Environment(SessionManager.self) private var session
	@State private var timer: Timer?
	@State private var elapsedTime: TimeInterval = 0
	@State private var isListeningBack = false

	var body: some View {
		VStack(spacing: 16) {
			Text(elapsedTime.formattedAsDuration())
				.font(.system(.title, design: .monospaced))
				.onAppear {
					if model.recordingStatus == .isRecording {
						startTimer()
					} // end if
				} // on appear
				.onDisappear {
					stopTimer()
				} // on disappear

			// buttons
			HStack(spacing: 20) {
				// show play button if recording is paused
				if model.recordingStatus == .isPaused {
					// play recording button
					Button(action: {
						if isListeningBack {
							model.audioPlayer?.stop()
							isListeningBack = false
						} else if let url = model.audioRecorder?.url {
							model.playRecording(url, context: context)
							isListeningBack = true
						} // end if
					}) {
						Label(isListeningBack ? "Pause" : "Play", systemImage: isListeningBack ? "stop.fill" : "headphones")
							.padding()
							.background(Color.purple.opacity(0.2))
							.clipShape(RoundedRectangle(cornerRadius: 10))
					} // button
				} else {
					Spacer()
				} // end if

				// recording control
				Button(action: {
					if model.recordingStatus == .isRecording {
						model.pauseRecording()
						stopTimer()
					} else if model.recordingStatus == .isPaused {
						model.resumeRecording(context: context)
						startTimer()
					}
				}) {
					Label(model.recordingStatus == .isRecording ? "Pause Recording" : "Resume", systemImage: model.recordingStatus == .isRecording ? "pause.circle" : "record.circle")
						.padding()
						.background(Color.blue.opacity(0.2))
						.clipShape(RoundedRectangle(cornerRadius: 10))
				}

				// show  a save button if recording is paused
				if model.recordingStatus == .isPaused {
					Button("Save") {
						if let user = session.user {
							model.stopRecording(forAuthor: user, context: context)
						} // end if
						stopTimer()
					} // button
					.padding()
					.background(Color.green.opacity(0.2))
					.clipShape(RoundedRectangle(cornerRadius: 10))
				} else {
					Spacer()
				} // end if is recording
			} // HStack
		} // VStack
		.padding()
	} // body

	private func startTimer() {
		elapsedTime = model.audioRecorder?.currentTime ?? 0
		timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
			if let current = model.audioRecorder?.currentTime {
				elapsedTime = current
			}
		}
	} // func

	private func stopTimer() {
		timer?.invalidate()
		timer = nil
	} // func
} // view
