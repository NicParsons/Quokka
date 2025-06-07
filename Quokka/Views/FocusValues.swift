import SwiftUI

extension FocusedValues {
// posts
	var post: Post?? {
		get { self[FocusedPostKey.self] }
		set { self[FocusedPostKey.self] = newValue }
	}

	var selectedPost: Post?? {
		get { self[FocusedPostSelectionKey.self] }
		set { self[FocusedPostSelectionKey.self] = newValue }
	}

	private struct FocusedPostKey: FocusedValueKey {
		typealias Value = Post?
	}

	private struct FocusedPostSelectionKey: FocusedValueKey {
		typealias Value = Post?
	}

	// recordings for legacy
	var recording: Recording?? {
		get { self[FocusedRecordingKey.self] }
		set { self[FocusedRecordingKey.self] = newValue }
	}

	var selection: Recording.ID?? {
		get { self[FocusedRecordingSelectionKey.self] }
		set { self[FocusedRecordingSelectionKey.self] = newValue }
	}

	private struct FocusedRecordingKey: FocusedValueKey {
		typealias Value = Recording?
	}

	private struct FocusedRecordingSelectionKey: FocusedValueKey {
		typealias Value = Recording.ID?
	}
}
