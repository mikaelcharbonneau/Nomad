//
//  User.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

nonisolated struct User: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var email: String
    var avatarURL: String?
    var isGuest: Bool

    static let guest = User(id: "guest", name: "Guest", email: "", avatarURL: nil, isGuest: true)
}
