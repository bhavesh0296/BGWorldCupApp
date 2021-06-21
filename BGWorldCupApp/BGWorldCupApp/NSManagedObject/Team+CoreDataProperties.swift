//
//  Team+CoreDataProperties.swift
//  BGWorldCupApp
//
//  Created by bhavesh on 21/06/21.
//  Copyright © 2021 Bhavesh. All rights reserved.
//
//

import Foundation
import CoreData


extension Team {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Team> {
        return NSFetchRequest<Team>(entityName: "Team")
    }

    @NSManaged public var wins: Int32
    @NSManaged public var losses: Int32
    @NSManaged public var imageName: String?
    @NSManaged public var teamName: String?
    @NSManaged public var qualifyingZone: String?

}
