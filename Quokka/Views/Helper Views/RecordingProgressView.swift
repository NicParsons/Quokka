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
					if model.isRecording {
						startTimer()
					}
				}
				.onDisappear {
					stopTimer()
				}

			HStack(spacing: 20) {
				Button(action: {
					if model.isRecording {
						model.resumeRecording(context: context)
						stopTimer()
					} else {
						model.startRecording(context: context)
						startTimer()
					}
				}) {
					Label(model.isRecording ? "Stop" : "Resume", systemImage: model.isRecording ? "pause.circle" : "play.circle")
						.padding()
						.background(Color.blue.opacity(0.2))
						.clipShape(RoundedRectangle(cornerRadius: 10))
				}

				Button("Save") {
					if let user = session.user {
						model.stopRecording(forAuthor: user, context: context)
					}
					stopTimer()
				}
				.padding()
				.background(Color.green.opacity(0.2))
				.clipShape(RoundedRectangle(cornerRadius: 10))
			}

			Button(action: {
				if isListeningBack {
					model.audioPlayer?.stop()
					isListeningBack = false
				} else if let url = model.audioRecorder?.url {
					try? model.playRecording(url, context: context)
					isListeningBack = true
				}
			}) {
				Label(isListeningBack ? "Stop Listening" : "Listen", systemImage: isListeningBack ? "stop.fill" : "headphones")
					.padding()
					.background(Color.purple.opacity(0.2))
					.clipShape(RoundedRectangle(cornerRadius: 10))
			}
		}
		.padding()
	}

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
