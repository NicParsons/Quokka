import SwiftUI

struct ExportButton: View {
	@Environment(Model.self) private var model
	let recordingFileName: String?

    var body: some View {
		Button("Export") {
			if let filename = recordingFileName {
				self.export(filename)
			} // if let
		} // Button
		.disabled(recordingFileName == nil)
    } // body

	func export(_ fileName: String) {
		let folderChooserPoint = CGPoint(x: 0, y: 0)
		let folderChooserSize = CGSize(width: 500, height: 600)
		let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
		let folderPicker = NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)
		folderPicker.canChooseDirectories = true
		folderPicker.canChooseFiles = false
		folderPicker.allowsMultipleSelection = false
		folderPicker.canDownloadUbiquitousContents = true
		folderPicker.canResolveUbiquitousConflicts = false

		folderPicker.begin { response in
			if response == .OK {
				let pickedFolder = folderPicker.url
				if let pickedFolder = pickedFolder {
					do {
					try model.export(fileName, to: pickedFolder)
					} catch {
	//TODO: display alert with the error encountered when exporting.
						print(error)
					} // do try catch
				}
} // end if
		} // completion handler
	} // func
} // View
