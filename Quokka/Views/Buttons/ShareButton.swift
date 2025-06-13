import SwiftUI

struct ShareButton: View {
	@Environment(Model.self) private var model
	let post: Post
    var body: some View {
		#if os(macOS)
			ShareLink(
				item: post.recording.fileURL,
				subject: Text(post.description.capitalizingFirstLetter()),
				message: Text(post.description.capitalizingFirstLetter()),
				preview: SharePreview(
					post.description.capitalizingFirstLetter(),
					image: Image(systemName: "waveform.circle")
				) // SharePreivew
			) // ShareLink
		#else
		ShareLink(
			item: post,
			subject: Text(post.description.capitalizingFirstLetter()),
			message: Text(post.description.capitalizingFirstLetter()),
			preview: SharePreview(
				post.description.capitalizingFirstLetter(),
				image: Image(systemName: "waveform.circle")
			) // SharePreivew
		) // ShareLink
		#endif
    } // body
} // view
