//
//  SavedFolder.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

struct SavedFolder: Identifiable {
    let id: String = UUID().uuidString
    var name: String
    var propertyIDs: [String] = []
    let createdAt: Date = Date()
}
