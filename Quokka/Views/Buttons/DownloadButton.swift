import SwiftUI

struct DownloadButton: View {
	@Environment(Model.self) private var model
	let recording: Recording
	@State private var error: Error?
	@State private var alertIsShown = false
	@State private var status: Recording.DownloadStatus = .unknown
    var body: some View {
		Button(
			action: {
				do {
					let _ = try model.download(recording)
					status = model.downloadStatus(for: recording)
				} catch {
					self.error = error
				} // do try catch
			}) {
				model.recordingStatusIndicator(for: recording)
			} // Button
			.disabled(status != .remote)

			.onAppear {
status = model.downloadStatus(for: recording)
			}

			.alert("Error downloading \(recording.shortDescription)",
				   isPresented: $alertIsShown) {
				Button("OK") {
					// do nothing
				} // Button
				} message: {
					Text(error?.localizedDescription ?? "")
			} // Alert
    } // body
} // View
