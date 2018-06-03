//
//  RouteBadges.swift
//  UHProject
//
//  Created by Felipe Antonio Cardoso on 03/06/2018.
//  Copyright © 2018 Felipe Antonio Cardoso. All rights reserved.
//

import Foundation

struct RouteBadge {
    
    static func badges() -> [RouteBadge] {
        return [
            RouteBadge(id:"free-sidewalk", name:"Calçadas Livres", image: "sidewalk"),
            RouteBadge(id:"light", name:"Iluminado", image: "light"),
            RouteBadge(id:"people", name:"Local Movimentado", image: "people"),
            RouteBadge(id:"hole-sidewalk", name:"Calçada com buraco", image: "hole"),
            RouteBadge(id:"crossing-road", name:"Faixa de pedestre", image: "crossing-walk"),
            RouteBadge(id:"no-light-sinalization", name:"Sem luz de pedestre", image: "no-light"),
        ]
    }
    
    let id: String
    let name: String
    let image: String
    
}
