import SwiftUI

extension View {
	@ViewBuilder func enableDeletingWithKeyboard(of selection: Optional<Any>, confirmationDialogIsShown: Binding<Bool>) -> some View {
		#if os(macOS)
self
			.onDeleteCommand(perform: {
				print("Delete key pressed.")
				if selection != nil { confirmationDialogIsShown.wrappedValue = true }
			} )
		#else
		self
		#endif
	}
}
