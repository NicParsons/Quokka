import SwiftUI

struct ShareButton: View {
	@Environment(Model.self) private var model
	let post: Post
    var body: some View {
		if let recording = post.recording {
#if os(macOS)
			ShareLink(
				item: model.recordingFileURL(for: recording.fileName),
				subject: Text(post.description.capitalizingFirstLetter()),
				message: Text(post.description.capitalizingFirstLetter()),
				preview: SharePreview(
					post.description.capitalizingFirstLetter(),
					image: Image(systemName: "waveform.circle")
				) // SharePreivew
			) // ShareLink
#else
			ShareLink(
				item: recording,
				subject: Text(post.description.capitalizingFirstLetter()),
				message: Text(post.description.capitalizingFirstLetter()),
				preview: SharePreview(
					post.description.capitalizingFirstLetter(),
					image: Image(systemName: "waveform.circle")
				) // SharePreivew
			) // ShareLink
#endif
		} // if let
    } // body
} // view
