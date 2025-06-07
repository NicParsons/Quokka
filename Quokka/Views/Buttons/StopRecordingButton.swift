import SwiftUI

struct StopRecordingButton: View {
	@Environment(Model.self) private var model

	var body: some View {
			Button(
				action: {
						model.stopRecording()
				}) {
						Label("Stop Recording", systemImage: "stop.circle")
			} // Button
				.disabled(!model.isRecording)
				.foregroundColor(.red)
	} // body
} // View

struct StopRecordingButton_Previews: PreviewProvider {
    static var previews: some View {
        StopRecordingButton()
    }
}

//  StopRecordingButton.swift
//  AudioDiary
//  Created by Nicholas Parsons on 22/4/2022.
