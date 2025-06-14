import SwiftUI

struct PostCapsuleView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Bindable var post: Post
	@State private var confirmationDialogIsShown = false

	var body: some View {
		HStack {
			HStack {
				nowPlayingIndicator
				Text("\(post.shortDescription.capitalizingFirstLetter()) (\(formattedDuration))")
			}
			.accessibilityElement(children: .combine)
			.accessibilityLabel(Text("\(post.shortDescription.capitalizingFirstLetter()) (\(formattedDuration)) \(nowPlaying() ? ", now playing" : "")"))
			#if os(macOS)
				Spacer()
			if let recording = post.recording {
				PlayPauseButton(recording: recording)
				DownloadButton(recording: recording)
			} // if let
			DeleteButton(shouldDelete: $confirmationDialogIsShown)
			#else
				post.recordingStatusIndicator
			#endif
		} // HStack
		.padding()
		.padding(.horizontal)
		.frame(minWidth: 100, maxWidth: 250)
		.frame(height: 50)
		.background(
			Capsule()
				.fill(Color.blue.opacity(0.15))
				.shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
		) // background
		.padding(.horizontal, 8)
		// macOS automatically combines the PostCapsule into one accessibility element which VoiceOver can interact with to access the child elements
		// but on iOS the elements are separate by default which makes navigating more verbose and will make it difficult to know which play/delete button relates to which entry
#if os(iOS)
.accessibilityElement(children: .combine)
.addDiaryEntryVOActions(model: model, context: context, selectedPost: post, confirmationDialogIsShown: $confirmationDialogIsShown)
		// combining the children means that the default action on the element triggers all child buttons
		// unless we override it like this
.accessibilityAction { playPause() }
#endif
		.onAppear {
				Task {
					if let recording = post.recording {
						// safe to unwrap
						post.recording!.duration = await recording.updatedDuration()
					} // if let
				} // task
		} // on appear
	} // body

	func nowPlaying() -> Bool {
		guard let recording = post.recording else { return false }
		return model.isPlaying(recording.fileURL)
	}

	func playPause() {
		guard let recording = post.recording else { return }
		nowPlaying() ? model.pause(context) : model.startPlaying(recording, context: context)
	}
} // View

extension PostCapsuleView {
	var nowPlayingIndicator: Image {
	if nowPlaying() {
		return Image(systemName: "waveform.circle.fill")
	} else {
return Image(systemName: "waveform.circle")
	} // end if
	} // variable

	var duration: TimeInterval {
		post.recording?.duration ?? 0
	} // duration

	var formattedDuration: String {
		if duration == 0 {
			return "❗️"
		} else {
			return duration.formattedAsDuration()
		} // end if
	} // formattedDuration
} // extension
