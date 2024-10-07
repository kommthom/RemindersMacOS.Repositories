//
//  DatabaseEmailTokenRepository.swift
//
//
//  Created by Thomas Benninghaus on 11.12.23.
//

import Vapor
import Fluent

public struct DatabaseEmailTokenRepository: EmailTokenRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    
    public func find(token: String) -> Future<EmailToken?> {
        return EmailToken.query(on: database)
            .filter(\.$token == token)
            .first()
    }
    
    public func create(_ emailToken: EmailToken) -> Future<Void> {
        return emailToken.create(on: database)
    }
    
    public  func delete(_ emailToken: EmailToken) -> Future<Void> {
        return emailToken.delete(on: database)
    }
    
    public func find(userID: UUID) -> Future<EmailToken?> {
        EmailToken.query(on: database)
            .filter(\.$user.$id == userID)
            .first()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var emailTokens: EmailTokenRepositoryProtocol {
        guard let factory = storage.makeEmailTokenRepository else {
            fatalError("EmailToken repository not configured, use: app.repositories.use")
        }
        return factory(app)
    }
    
    public func use(_ make: @escaping (Application) -> (EmailTokenRepositoryProtocol)) {
        storage.makeEmailTokenRepository = make
    }
}
