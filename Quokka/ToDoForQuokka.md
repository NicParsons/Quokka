#  To Do for Quokka.app

## Bugs

* Selection in Journal View not working. Added print statements and also text at the bottom of the view to display the selectedPost for debug purposes.
* iOS and macOS seem to have their own separate posts perhaps because the file path to the documents folder is different on each! 😱 I'll have to store only the filename and extenssion as a string and then recreate the full url, perhaps in a Model method, on the fly.
* need sound for saving recording: 1009, 1330, 1352, 1109
* keyboard shortcut for share button in file menu not working
* using ModelContext in background thread: 	•	This warning means your ModelContext was created on the main thread, but you’re using it on a background thread (perhaps during background tasks like cleaning up posts). This can cause race conditions or crashes in the future. ✅ Fix: Either use a @ModelActor, or dispatch back to the main queue when using ModelContext.

## Features

* assign author to recording when importing
* wrap it up reminder
* conversation/thread view, might require adding recipients property to Post
* instead of custom NowPlayingView, use AVPlayerView on macOS and AVPlayerViewControler on iOS
* playback should integrate with system's now playing API
* Add Download button to File menu
* add OBFoundation as a dependancy (it wil need to be published first) and then update print statements to use OBFoundation's logging system
* increment listen count of Post after recording finishes playback
* visually distinguish PostCapsule views depending on whether listenCount is > or = 0
