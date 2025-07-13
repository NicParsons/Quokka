#  To Do for Quokka.app

## Bugs

* need sound for saving recording: 1009, 1330, 1352, 1109
* selection in Journal View not working
* playback position not saving
* on macOS, it's possible to have the same recording playing twice at different playback positions if you use both space bar and return to start playback (i.e. playing state and playback position is not synced between the window view and the menu bar controls)
* keyboard shortcut for share button in file menu not working
* using ModelContext in background thread: 	•	This warning means your ModelContext was created on the main thread, but you’re using it on a background thread (perhaps during background tasks like cleaning up posts).
	•	This can cause race conditions or crashes in the future.
	•	✅ Fix: Either use a @ModelActor, or dispatch back to the main queue when using ModelContext.


## Features

* conversation/thread view, might require adding recipients property to Post
* playback should integrate with system's now playing API
* playback speed control for NowPlayingView
* Add Download button to File menu
* add OBFoundation as a dependancy (it wil need to be published first) and then update print statements to use OBFoundation's logging system
* increment listen count of Post after recording finishes playback
* visually distinguish PostCapsule views depending on whether listenCount is > or = 0
