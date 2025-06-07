import SwiftUI

struct DownloadButton: View {
	let recording: Recording
	@State private var error: Error?
	@State private var alertIsShown = false
    var body: some View {
		Button(
			action: {
				do {
				let _ = try recording.download()
				} catch {
					self.error = error
				} // do try catch
			}) {
				recording.statusIndicator
			} // Button
			.disabled(recording.status != .remote)
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
