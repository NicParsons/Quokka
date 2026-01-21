#  To Do for Quokka.app

## Bugs

* on iOS, NowPlaying View ignores safe area and overlaps TabView tabs at the bottom of the screen
* on macOS, selection persistance not working
* on macOS, play/pause using return as keyboard shortcut not working in Convesation view (but working in Journal view)
* need sound for saving recording: 1009, 1330, 1352, 1109
* keyboard shortcut for share button in file menu not working
* focus issues when a post is selected in today view
* using ModelContext in background thread: 	•	This warning means your ModelContext was created on the main thread, but you’re using it on a background thread (perhaps during background tasks like cleaning up posts). This can cause race conditions or crashes in the future. ✅ Fix: Either use a @ModelActor, or dispatch back to the main queue when using ModelContext.

## Features

* conversation/thread view, might require adding recipients property to Post
* rename file name when assigning author
* assign author to recording when importing
* wrap it up reminder
* instead of custom NowPlayingView, use AVPlayerView on macOS and AVPlayerViewControler on iOS
* playback should integrate with system's now playing API
* Add Download button to File menu
* add OBFoundation as a dependancy (it wil need to be published first) and then update print statements to use OBFoundation's logging system
* increment listen count of Post after recording finishes playback
* visually distinguish PostCapsule views depending on whether listenCount is > or = 0
* look at integrating todos from AudioDiary
