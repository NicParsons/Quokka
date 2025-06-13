import SwiftUI

struct TestShareView: View {
		var body: some View {

			ShareLink(item: createTempFile()) {
				Label("Share Test File", systemImage: "square.and.arrow.up")
			} // ShareLink
			.padding()
		} // body

	private func createTempFile() -> URL {
		let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
		try? "Hello world!".write(to: testURL, atomically: true, encoding: .utf8)
		return testURL
	} // func
	} // view
