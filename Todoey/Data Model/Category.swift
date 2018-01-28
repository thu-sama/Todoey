//
//  Category.swift
//  Todoey
//
//  Created by Tun Lin Thu on 2018/01/27.
//  Copyright © 2018 Tun Lin Thu. All rights reserved.
//

import Foundation
import RealmSwift

class Category: Object {
    @objc dynamic var name = ""
    @objc dynamic var color = ""
    @objc dynamic var dateCreated = Date()
    let items = List<Item>()
}
