import SwiftUI

struct PlaybackRateControl: View {
	@Environment(Model.self) private var model
	var minValue: Float = 0.5
	var maxValue: Float = 3.0
	var stepValue: Float = 0.1

	var body: some View {
		Slider(value: playbackRate, in: minValue...maxValue, step: stepValue)
			.accessibilityLabel("Playback speed")
		// using playbackRate in the accessibility value has unintended consequences
		// VoiceOver reads out the code for the Binding definition etc
		// and using wrappedValue VoiceOver reads out a large number of decimal places e.g. one point zero zero zero zero zero zero zero
			.accessibilityValue("\(formattedPlaybackRate) times")
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

	var formattedPlaybackRate: String {
let formatter  = NumberFormatter()
		formatter.minimumFractionDigits = 1
		formatter.maximumFractionDigits = 2
		return formatter.string(from: NSNumber(value: playbackRate.wrappedValue)) ?? ""
	}

	var sliderLength: CGFloat {
CGFloat((maxValue - minValue) / stepValue)
	} // sliderLength
} // extension
