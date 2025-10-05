//
//  Item.swift
//  Dopamine Detox
//
//  Created by Federico Garcia Lorca on 10/5/25.
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
