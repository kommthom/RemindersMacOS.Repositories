//
//  DatabaseLocalizationRepository.swift
//
//
//  Created by Thomas Benninghaus on 14.05.24.
//

import Vapor
import Fluent
import DTO

public struct DatabaseLocalizationRepository: LocalizationRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.localization")
    
    public init(database: Database) {
        self.database = database
    }
    
    public func create(_ localization: LocalizationModel) -> Future<Void> {
        return localization
                .create(on: database)
                .flatMapErrorThrowing {
                    if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                        logger.error("Create Localization: duplicate key -> \(localization.$key)")
                        throw LocalizationControllerError.unableToCreateNewRecord
                    }
                    logger.error("Create Localization: error -> \($0.localizedDescription)")
                    throw $0
                }
    }
    
    public func create(_ localizations: [LocalizationModel]) -> Future<Void> {
        return localizations
                .create(on: database)
    }
    
    public func delete(id: UUID?, force: Bool) -> Future<Void> {
        return LocalizationModel
            .query(on: database)
            .filter(\.$id == id!)
            .delete()
    }
    
    public func find(id: UUID?) -> Future<LocalizationModel?> {
        return LocalizationModel
            .find(id, on: database)
    }
    
    public func find(userName: String, locale: String, key: String) -> Future<LocalizationModel?> {
        return LocalizationModel
            .query(on: database)
            .filter(\.$key == key)
            .filter(\.$languageCode ~~ [userName, locale])
            .first()
    }
    
    // find KeyWord
    public func find(locale: String, key: KeyWord) -> Future<LocalizationModel?> {
        return LocalizationModel
            .query(on: database)
            .filter(\.$enumKey == key.rawValue)
            .filter(\.$languageCode == locale)
            .first()
    }
    
    public func find(locale: String, enumKey: Int) -> Future<LocalizationModel?> {
        return LocalizationModel
            .query(on: database)
            .filter(\.$enumKey == enumKey)
            .filter(\.$languageCode == locale)
            .first()
    }
    
    public func set(_ localization: LocalizationModel) -> Future<Void> {
        return LocalizationModel
            .query(on: database)
            .filter(\.$id == localization.id!)
            .set(\.$key, to: localization.key)
            .set(\.$value, to: localization.value)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<LocalizationModel, Field>, to value: Field.Value, for localizationID: UUID) -> Future<Void> where Field : QueryableProperty, Field.Model == LocalizationModel {
        return LocalizationModel
            .query(on: database)
            .filter(\.$id == localizationID)
            .set(field, to: value)
            .update()
    }

    public func allLocales() -> Future<[String]> {
        return LocalizationModel
            .query(on: database)
            .unique()
            .all(\.$languageCode)
            .map { $0 }
    }
    
    public func all() -> Future<[LocalizationModel]> {
        return LocalizationModel
            .query(on: database)
            .filter(\.$enumKey == nil)
            .all()
    }
    
    public func all(locale: String) -> Future<[LocalizationModel]> {
        return LocalizationModel
            .query(on: database)
            .filter(\.$enumKey == nil)
            .filter(\.$languageCode == locale)
            .all()
    }
    
    public func allKeyWords() -> Future<[LocalizationModel]> {
        return LocalizationModel
            .query(on: database)
            .filter(\.$enumKey != nil)
            .all()
    }
}

extension Application.Repositories {
    public var localizations: LocalizationRepositoryProtocol {
        guard let storage = storage.makeLocalizationRepository else {
            fatalError("LocalizationRepository not configured, use: app.localizationRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (LocalizationRepositoryProtocol)) {
        storage.makeLocalizationRepository = make
    }
}
