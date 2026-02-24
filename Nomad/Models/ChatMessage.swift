//
//  ChatMessage.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

struct ChatMessage: Identifiable {
    let id: String
    var content: String
    let isUser: Bool
    let timestamp: Date
    var properties: [Property]
    var isStreaming: Bool

    init(id: String = UUID().uuidString, content: String, isUser: Bool, timestamp: Date = Date(), properties: [Property] = [], isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.properties = properties
        self.isStreaming = isStreaming
    }
}
