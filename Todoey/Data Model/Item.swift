//
//  Item.swift
//  Todoey
//
//  Created by Tun Lin Thu on 2018/01/27.
//  Copyright © 2018 Tun Lin Thu. All rights reserved.
//

import Foundation
import RealmSwift

class Item : Object{
    @objc dynamic var title = ""
    @objc dynamic var done = false
    @objc dynamic var dateCreated : Date?
    var parentCategory = LinkingObjects(fromType: Category.self, property: "items")
}
