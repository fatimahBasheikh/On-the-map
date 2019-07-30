//
//  StudentInfo.swift
//  on the map
//
//  Created by fatoom on 10/10/1440 AH.
//  Copyright © 1440 Udacity. All rights reserved.
//

import Foundation

struct StudentInfo: Codable {
    let name: String
    enum CodingKeys: String, CodingKey {
        case name = "nickname"
    }
}

