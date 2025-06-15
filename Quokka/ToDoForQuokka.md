#  To Do for Quokka.app

## Bugs

* fix bug with navigation following making TabView sidebar adaptable
* playback position not saving
* on macOS, it's possible to have the same recording playing twice at different playback positions if you use both space bar and return to start playback

## Features

* recording.date when importing file should be based on the file's creation date
* conversation/thread view, might require adding recipients property to Post
* playback should integrate with system's now playing API
* add OBFoundation as a dependancy (it wil need to be published first) and then update print statements to use OBFoundation's logging system
* increment listen count of Post after recording finishes playback
* visually distinguish PostCapsule views depending on whether listenCount is > or = 0
