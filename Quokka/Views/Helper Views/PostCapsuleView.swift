import SwiftUI

struct PostCapsuleView: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	let post: Post
	@State private var confirmationDialogIsShown = false
	@State private var duration: Int = 0

	var body: some View {
		HStack {
			HStack {
				nowPlayingIndicator
				Text("\(post.shortDescription.capitalizingFirstLetter()) (\(duration == 0 ? "" : duration.formattedAsDuration()))")
			}
			.accessibilityElement(children: .combine)
			.accessibilityLabel(Text("\(post.shortDescription.capitalizingFirstLetter()) (\(duration == 0 ? "-" : duration.formattedAsDuration())) \(nowPlaying() ? ", now playing" : "")"))
			#if os(macOS)
			if let recording = post.recording {
				Spacer()
				PlayPauseButton(recording: recording)
				DownloadButton(recording: recording)
			} // if let
			DeleteButton(shouldDelete: $confirmationDialogIsShown)
			#else
			if let recording = post.recording {
				recording.statusIndicator
			} else {
Image(systemName: "exclamationmark.bubble")
			} // if let
			#endif
		} // HStack
		.padding()
		.padding(.horizontal)
		.frame(maxWidth: .infinity)
		.frame(height: 50)
		.background(
			Capsule()
				.fill(Color.blue.opacity(0.15))
				.shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
		) // background
		.padding(.horizontal, 8)
		// .confirmDeletion(ofSelected: $post, if: $confirmationDialogIsShown)
		// macOS automatically combines the RecordingRow into one accessibility element which VoiceOver can interact with to access the child elements
		// but on iOS the elements are separate by default which makes navigating more verbose and will make it difficult to know which play/delete button relates to which entry
#if os(iOS)
.accessibilityElement(children: .combine)
.addDiaryEntryVOActions(model: model, context: context, selectedPost: post, confirmationDialogIsShown: $confirmationDialogIsShown)
		// combining the children means that the default action on the element triggers all child buttons
		// unless we override it like this
.accessibilityAction { playPause() }
#endif
		.onAppear {
			if let recording = post.recording {
				Task {
					await duration = recording.duration()
				}
			} // if let
		}
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
}
