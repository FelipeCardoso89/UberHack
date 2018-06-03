//
//  RouteComments.swift
//  UHProject
//
//  Created by Felipe Antonio Cardoso on 03/06/2018.
//  Copyright © 2018 Felipe Antonio Cardoso. All rights reserved.
//

import Foundation

struct RouteComments {
    
    static func comments() -> [RouteComments] {
        return [
            RouteComments(id: "comment_1", name: "Rafael", comment: "Caminho tranquilo!"),
            RouteComments(id: "comment_2", name: "Marcela", comment: "As cerejeiras estão mais bonitas do que nunca!"),
            RouteComments(id: "comment_3", name: "Pamela", comment: "Cuidado, tem um buraco meio escondido!"),
        ]
    }
    
    let id: String
    let name: String
    let comment: String
}
