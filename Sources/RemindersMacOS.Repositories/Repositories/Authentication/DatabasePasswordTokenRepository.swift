//
//  DatabasePasswordTokenRepository.swift
//
//
//  Created by Thomas Benninghaus on 11.12.23.
//

import Vapor
import Fluent

public struct DatabasePasswordTokenRepository: PasswordTokenRepositoryProtocol, DatabaseRepositoryProtocol {
    public var database: Database
    
    public func find(userID: UUID) -> Future<PasswordToken?> {
        PasswordToken.query(on: database)
            .filter(\.$user.$id == userID)
            .first()
     }
    
    public func find(token: String) -> Future<PasswordToken?> {
        PasswordToken.query(on: database)
            .filter(\.$token == token)
            .first()
    }
    
    public func count() -> Future<Int> {
        PasswordToken.query(on: database).count()
    }
    
    public func create(_ passwordToken: PasswordToken) -> Future<Void> {
        passwordToken.create(on: database)
    }
    
    public func delete(_ passwordToken: PasswordToken) -> Future<Void> {
        passwordToken.delete(on: database)
    }
    
    public func delete(for userID: UUID) -> Future<Void> {
        PasswordToken.query(on: database)
            .filter(\.$user.$id == userID)
            .delete()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var passwordTokens: PasswordTokenRepositoryProtocol {
        guard let factory = storage.makePasswordTokenRepository else {
            fatalError("PasswordToken repository not configured, use: app.repositories.use")
        }
        return factory(app)
    }
    
    public func use(_ make: @escaping (Application) -> (PasswordTokenRepositoryProtocol)) {
        storage.makePasswordTokenRepository = make
    }
}
