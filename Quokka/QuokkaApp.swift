import SwiftUI
import SwiftData

@main
struct QuokkaApp: App {
	@State private var model = Model()
	@State private var session = SessionManager()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
			User.self,
			Post.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
				.environment(model)
				.environment(session)
#if os(iOS)
.accessibilityAction(.magicTap) {
if model.isPlaying {
	model.pause(sharedModelContainer.mainContext)
} else if model.isRecording {
	model.stopRecording(forAuthor: session.user, context: sharedModelContainer.mainContext)
} else {
	/* we can do this once we add property to model to detect whether playback is paused
	model.resumePlayback()
	 */
	model.startRecording()
} // end if
} // magic tap action
#endif
        } // window group
        .modelContainer(sharedModelContainer)
		.commands {
			FileMenu(model: model)
			PlaybackControlsMenu(model: model, session: session)
		} // commands
    } // body
} // app
