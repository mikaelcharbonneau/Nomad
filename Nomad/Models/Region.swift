//
//  Region.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

nonisolated struct Region: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let cities: [String]
}

let sampleRegions: [Region] = [
    Region(id: "r1", name: "Greater Montreal", cities: ["Montreal", "Laval", "Longueuil", "Brossard", "Terrebonne", "Blainville"]),
    Region(id: "r2", name: "Quebec City", cities: ["Quebec City", "Lévis", "Beauport", "Charlesbourg", "Sainte-Foy"]),
    Region(id: "r3", name: "Laurentians", cities: ["Mont-Tremblant", "Saint-Sauveur", "Sainte-Adèle", "Saint-Jérôme"]),
    Region(id: "r4", name: "Eastern Townships", cities: ["Sherbrooke", "Magog", "Granby", "Bromont"]),
    Region(id: "r5", name: "Chaudière-Appalaches", cities: ["Saint-Georges", "Thetford Mines", "Beaulac Garthby", "Montmagny"]),
    Region(id: "r6", name: "Outaouais", cities: ["Gatineau", "Chelsea", "Cantley", "Val-des-Monts"]),
    Region(id: "r7", name: "Lanaudière", cities: ["Joliette", "Repentigny", "L'Assomption", "Mascouche"]),
    Region(id: "r8", name: "Mauricie", cities: ["Trois-Rivières", "Shawinigan", "Cap-de-la-Madeleine"]),
]
