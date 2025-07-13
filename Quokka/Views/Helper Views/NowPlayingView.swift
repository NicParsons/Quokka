import SwiftUI

struct NowPlayingView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@State private var currentTime: TimeInterval = 0
	@State private var isSeeking = false
	@State private var timer: Timer?

	var body: some View {
		VStack(spacing: 16) {
			Text(model.currentlyPlayingRecording?.description.capitalizingFirstLetter() ?? "Nothing Playing")
				.font(.headline)
				.accessibilityAddTraits(.isHeader)

			// Scrubber above controls
			VStack {
				Slider(
					value: currentTimeBinding,
					in: 0...duration
				) {
					Text("Playback position")
				} minimumValueLabel: {
					Text(0.formattedAsDuration())
				} maximumValueLabel: {
					Text(model.currentlyPlayingRecording?.duration.formattedAsDuration() ?? "-")
				} onEditingChanged: { editing in
					if !editing {
						model.setPlaybackPosition(to: currentTime, context: context)
						isSeeking = false
					} // end if
				} // on editing Slider
				.accessibilityValue(Text("\(currentTime.formattedAsDuration()) elapsed of \(model.currentlyPlayingRecording?.duration.formattedAsDuration() ?? "n/a")"))
				.disabled(model.currentlyPlayingRecording == nil)
			} // V Stack for scrubber

			// Playback controls
			HStack {
				Button(action: {
					model.seekBackward(15, context: context)
				}) {
					Label("Go backward 15 seconds", systemImage: "gobackward.15")
				} // button
				.accessibilityLabel("Go backward 15 seconds")

				PlayPauseButton(recording: model.currentlyPlayingRecording)

				Button(action: {
					model.seekForward(15, context: context)
				}) {
					Label("Go forward 15 seconds", systemImage: "goforward.15")
				} // button
				.accessibilityLabel("Go forward 15 seconds")
			} // H Stack for playback controls

			PlaybackRateControl()
		} // V Stack
		.padding()
		.frame(maxWidth: 500)
		.frame(minHeight: 150, maxHeight: 250)
		.onAppear {
			Task {
					startTimer()
await updateDuration()
			} // task
		} // on appear
		.onDisappear {
			stopTimer()
		} // on disappear
		.onChange(of: model.currentlyPlayingRecording) {
			Task {
				await updateDuration()
			}
		} // on change
	} // body

	func startTimer() {
		timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
			guard !isSeeking, let player = model.audioPlayer else { return }
			currentTime = player.currentTime
		} // timer
	} // func

	func stopTimer() {
		timer?.invalidate()
		timer = nil
	} // func

	private func updateDuration() async {
		if let _ = model.currentlyPlayingRecording { await model.currentlyPlayingRecording!.duration = model.currentlyPlayingRecording!.updatedDuration() }
	} // func
} // View

extension NowPlayingView {
	var duration: TimeInterval {
		if let recording = model.currentlyPlayingRecording {
			return recording.duration
		} else {
return 0
		}
	}

	var currentTimeBinding: Binding<TimeInterval> {
		Binding(
			get: { currentTime },
			set: { newValue in
				currentTime = newValue
				isSeeking = true
			} // setter
		) // Binding
	} // computed property
} // extension

struct PlaybackRateControl: View {
	@Environment(Model.self) private var model
	var minValue: Float = 0.5
	var maxValue: Float = 3.0
	var stepValue: Float = 0.1

	var body: some View {
		Slider(value: playbackRate, in: minValue...maxValue, step: stepValue)
			.accessibilityLabel("Playback speed")
			.accessibilityValue("\(playbackRate) times")
			.frame(minWidth: sliderLength, maxWidth: sliderLength * 10)
	} // body
} // view

extension PlaybackRateControl {
	var playbackRate: Binding<Float> {
		Binding<Float>(
			get: { model.playbackRate },
			set: { newValue in model.playbackRate = newValue }
		)
	}

	var sliderLength: CGFloat {
CGFloat((maxValue - minValue) / stepValue)
	} // sliderLength
} // extension
