import SwiftUI
import UniformTypeIdentifiers

struct ImportButton: View {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
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
						if model.recordingFileExists(withFileName: url.lastPathComponent) {
							self.error = ImportError.fileNameClash(url.lastPathComponent)
							alertIsShowing = true
						} else {
							do {
								let _ = try model.importRecording(url, toContext: context)
							} catch {
								self.error = error
								alertIsShowing = true
							} // do try catch
						} // end if
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

enum ImportError: Error {
	case fileNameClash(String)
	case recordingAlreadyExists(String)
	case otherError(String)
} // enum

extension ImportError: CustomStringConvertible {
	var description: String {
		switch self {
		case let .fileNameClash(fileName):
return "The app already has a recording with that same name, \(fileName)."
		case let .recordingAlreadyExists(message):
return "Looks like you already have that recording. At least, you have a file with the same name, same size, same recording duration and same creation date: \(message)"
		case let .otherError(errorMessage):
			return "There was an error trying to import that file. The error message was: \(errorMessage)."
		} // switch
	} // description
} // extension
