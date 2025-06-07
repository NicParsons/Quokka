import SwiftUI

struct TodayViewLabel: View {
    var body: some View {
		Label("Today", systemImage: "record.circle")
    }
}

struct TodayViewLabel_Previews: PreviewProvider {
    static var previews: some View {
        TodayViewLabel()
    }
}
