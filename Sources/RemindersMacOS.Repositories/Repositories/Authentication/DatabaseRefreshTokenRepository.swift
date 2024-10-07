//
//  DatabaseRefreshTokenRepository.swift
//
//
//  Created by Thomas Benninghaus on 11.12.23.
//

import Vapor
import Fluent

public struct DatabaseRefreshTokenRepository: RefreshTokenRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend")
    
    public func create(_ token: RefreshToken) -> Future<Void> {
        logger.info("Create new refresh token: \(token)")
        return token
            .create(on: database)
            .flatMapErrorThrowing {
                logger.error("Create new refresh token: error -> \($0.localizedDescription)")
                throw $0
            }
    }
    
    public func find(id: UUID?) -> Future<RefreshToken?> {
        return RefreshToken.find(id, on: database)
    }
    
    public func find(token: String) -> Future<RefreshToken?> {
        return RefreshToken.query(on: database)
            .filter(\.$token == token)
            .first()
    }
    
    public func delete(_ token: RefreshToken) -> Future<Void> {
        token.delete(on: database)
    }
    
    public func count() -> Future<Int> {
        return RefreshToken.query(on: database)
            .count()
    }
    
    public func delete(for userID: UUID) -> Future<Void> {
        RefreshToken.query(on: database)
            .filter(\.$user.$id == userID)
            .delete()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var refreshTokens: RefreshTokenRepositoryProtocol {
        guard let factory = storage.makeRefreshTokenRepository else {
            fatalError("RefreshToken repository not configured, use: app.repositories.use")
        }
        return factory(app)
    }
    
    public func use(_ make: @escaping (Application) -> (RefreshTokenRepositoryProtocol)) {
        storage.makeRefreshTokenRepository = make
    }
}
