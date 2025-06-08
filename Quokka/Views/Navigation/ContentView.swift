import SwiftUI

struct ContentView: View {
	@Environment(Model.self) private var model
	@Environment(SessionManager.self) private var session
	@Environment(\.modelContext) private var context
	@State private var loggedIn = false

	var body: some View {
		VStack {
			if loggedIn {
				HomeScreen()
			} else {
NewUserView(done: $loggedIn, automaticallyLogIn: true)
			} // end if
	} // VStack
		.onAppear {
			do {
				try session.login(context: context)
				if let _ = session.user { loggedIn = true }
			} catch {
				print("Error logging in: \(error.localizedDescription)")
			}
		} // on appear
    } // body
} // view
