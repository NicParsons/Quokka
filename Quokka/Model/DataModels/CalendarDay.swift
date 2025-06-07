import Foundation

struct CalendarDay: Hashable, Identifiable {
	let id: Date
	var date: Date { id }
	var posts = [Post]()

	init(for date: Date) {
		id = Calendar.current.startOfDay(for: date)
	}
}

