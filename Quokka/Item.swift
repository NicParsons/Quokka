//
//  Item.swift
//  Quokka
//
//  Created by Nicholas Parsons on 16/5/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
