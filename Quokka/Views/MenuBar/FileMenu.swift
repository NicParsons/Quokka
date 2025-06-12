import SwiftUI

struct FileMenu: Commands {
@State private var model = Model()
	@FocusedValue(\.recording) private var selectedRecording: Recording??
	var body: some Commands {
		CommandGroup(after: .newItem) {
			ImportButton()
				.environment(model)
			#if os(macOS)
			if let recording = selectedRecording {
				ExportButton(recordingURL: recording?.fileURL)
					.environment(model)
				.keyboardShortcut("e", modifiers: [.command])
			} else {
				ExportButton(recordingURL: nil)
					.environment(model)
			} // if let
			#endif
		} // command group
	} // body
} // Commands struct
