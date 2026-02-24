//
//  AppViewModel.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

@Observable
@MainActor
class AppViewModel {
    var savedPropertyIDs: Set<String> = []
    var dislikedPropertyIDs: Set<String> = []
    var folders: [SavedFolder] = [SavedFolder(name: "Favorites")]
    var propertyNotes: [String: String] = [:]
    var savedSearchNotifications: Bool = false
    var savedSearchEmail: Bool = false

    let database = PropertyDatabase.shared
    let authService = AuthService.shared
    let chatService = ChatService()

    var savedProperties: [Property] {
        database.properties.filter { savedPropertyIDs.contains($0.id) }
    }

    func toggleSaved(_ property: Property) {
        if savedPropertyIDs.contains(property.id) {
            savedPropertyIDs.remove(property.id)
            for i in folders.indices {
                folders[i].propertyIDs.removeAll { $0 == property.id }
            }
        } else {
            savedPropertyIDs.insert(property.id)
            if !folders.isEmpty {
                folders[0].propertyIDs.append(property.id)
            }
        }
    }

    func isSaved(_ property: Property) -> Bool {
        savedPropertyIDs.contains(property.id)
    }

    func dislike(_ property: Property) {
        dislikedPropertyIDs.insert(property.id)
    }

    func addFolder(_ name: String) {
        folders.append(SavedFolder(name: name))
    }

    func deleteFolder(at offsets: IndexSet) {
        folders.remove(atOffsets: offsets)
    }

    func moveProperty(_ propertyID: String, to folder: SavedFolder) {
        for i in folders.indices {
            folders[i].propertyIDs.removeAll { $0 == propertyID }
        }
        if let idx = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[idx].propertyIDs.append(propertyID)
        }
    }
}
