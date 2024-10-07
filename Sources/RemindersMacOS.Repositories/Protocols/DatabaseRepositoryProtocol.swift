//
//  DatabaseRepositoryProtocol.swift
//
//
//  Created by Thomas Benninghaus on 22.12.23.
//

import Vapor
import Fluent

public protocol DBRepositoryProtocol: RequestServiceProtocol {}

public protocol DatabaseRepositoryProtocol: DBRepositoryProtocol {
    var database: Database { get }
    init(database: Database)
}

extension DatabaseRepositoryProtocol {
    public func `for`(_ req: Request) -> Self {
        return Self.init(database: req.db)
    }
}
