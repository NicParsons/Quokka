import SwiftUI
import UniformTypeIdentifiers

struct ImportButton: View {
	@Environment(Model.self) private var model
	@State private var showImporter = false
	@State private var alertIsShowing = false
	@State private var error: Error?
    var body: some View {
        Button(
			action: { showImporter = true }) {
				Label("Import Audio Files", systemImage: "square.and.arrow.down")
					.frame(width: 100, height: 50, alignment: .center)
					.cornerRadius(8)
			} // Button
			.keyboardShortcut("o", modifiers: [.command])
			.fileImporter(isPresented: $showImporter,
						  allowedContentTypes: [UTType.audio],
			allowsMultipleSelection: true) { result in
				switch result {
				case .success(let urls):
					for url in urls {
					do {
					let _ = try model.importRecording(url)
					} catch {
						self.error = error
alertIsShowing = true
					} // do try catch
					} // loop
				case .failure(let importError):
					self.error = importError
alertIsShowing = true
				} // Switch
			} // completion handler
						  .alert("Unable to import your file.",
								 isPresented: $alertIsShowing) {
							  Button("OK") {
								  // do nothing, I guess
							  }
						  } message: {
							  Text(error?.localizedDescription ?? "Please contact the developer with as much detail about the issue as you can.")
						  }
    } // body
} // view
