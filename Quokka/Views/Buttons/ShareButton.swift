import SwiftUI

struct ShareButton: View {
	@Environment(Model.self) private var model
	let recording: Recording
    var body: some View {
ShareLink(
	item: recording,
	subject: Text(recording.description.capitalizingFirstLetter()),
	message: Text(recording.description.capitalizingFirstLetter()),
	preview: SharePreview(
		recording.description.capitalizingFirstLetter(),
		image: Image(systemName: "waveform.circle")
	) // SharePreivew
) // ShareLink
    }
}
