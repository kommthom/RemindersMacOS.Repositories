//
//  DatabaseLanguageRepository.swift
//  
//
//  Created by Thomas Benninghaus on 18.05.24.
//

import Vapor
import Fluent
import DTO

public struct DatabaseLanguageRepository: LanguageRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.countries")
    
    public func create(_ language: LanguageModel) -> Future<Void> {
        logger.info("Create Language: \(language.$name)")
        return language
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Language: duplicate key -> \(language.$name)")
                    throw LanguageControllerError.unableToCreateNewRecord
                }
                logger.error("Create Language: error -> \($0.localizedDescription)")
                throw $0
            }
    }
    
    public func delete(id: UUID) -> Future<Void> {
        return LanguageModel
            .query(on: database)
            .filter(\.$id == id)
            .delete()
    }
    
    public func all() -> Future<[LanguageModel]> {
        return LanguageModel
            .query(on: database)
            .all()
    }
    
    public func find(id: UUID?) -> Future<LanguageModel?> {
        return LanguageModel
            .find(id, on: database)
    }
    
    public func find(name: String) -> Future<LanguageModel?> {
        return LanguageModel
            .query(on: database)
            .filter(\.$name == name)
            .first()
    }
    
    public func find(identifier: LanguageIdentifier) -> Future<LanguageModel?> {
        return LanguageModel
            .query(on: database)
            .filter(\.$identifier == identifier)
            .first()
    }
    
    public func set(_ language: LanguageModel) -> Future<Void> {
        return LanguageModel
            .query(on: database)
            .filter(\.$id == language.id!)
            .set(\.$identifier, to: language.identifier)
            .set(\.$name, to: language.name)
            .set(\.$longName, to: language.longName)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<LanguageModel, Field>, to value: Field.Value, for languageID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LanguageModel
    {
        return LanguageModel
            .query(on: database)
            .filter(\.$id == languageID)
            .set(field, to: value)
            .update()
    }
    
    public func count() -> Future<Int> {
        return LanguageModel
            .query(on: database)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var languages: LanguageRepositoryProtocol {
        guard let storage = storage.makeLanguageRepository else {
            fatalError("LanguageRepository not configured, use: app.languageRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (LanguageRepositoryProtocol)) {
        storage.makeLanguageRepository = make
    }
}

