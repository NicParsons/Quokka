import SwiftUI

struct DeleteConfirmationDialog: ViewModifier {
	@Environment(Model.self) private var model
	@Environment(\.modelContext) private var context
	@Binding var selectedPost: Post?
	@Binding var confirmationDialogIsShown: Bool

	func body(content: Content) -> some View {
content
			.confirmationDialog("Delete \(selectedPost?.description ?? "nothing")?",
								isPresented: $confirmationDialogIsShown,
								titleVisibility: .visible,
								presenting: selectedPost) { post in
				Button(role: .destructive) {
					model.delete(post, fromContext: context)
					selectedPost = nil
			} label: {
				Text("Delete")
				} // button
				Button("Cancel", role: .cancel) {
	// do nothing
				}
			} message: { _ in
				Text("Deleting this entry will remove it from iCloud and from all your devices signed into iCloud. This action cannot be undone.")
			} // confirmation dialog
	}
}

extension View {
	func confirmDeletion(ofSelected post: Binding<Post?>, if confirmationDialogIsShown: Binding<Bool>) -> some View {
		modifier(DeleteConfirmationDialog(selectedPost: post, confirmationDialogIsShown: confirmationDialogIsShown))
	}
}
