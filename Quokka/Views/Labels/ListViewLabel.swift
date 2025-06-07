import SwiftUI

struct ListViewLabel: View {
    var body: some View {
		Label("Journal", systemImage: "book.circle")
    }
}

struct ListViewLabel_Previews: PreviewProvider {
    static var previews: some View {
        ListViewLabel()
    }
}
