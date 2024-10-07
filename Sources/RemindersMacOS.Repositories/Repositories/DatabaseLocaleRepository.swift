//
//  DatabaseLocaleRepository.swift
//
//
//  Created by Thomas Benninghaus on 18.05.24.
//

import Vapor
import Fluent
import DTO

public struct DatabaseLocaleRepository: LocaleRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.countries")
    
    public func create(_ locale: LocaleModel) -> Future<Void> {
        logger.info("Create Locale: \(locale.$name)")
        return locale
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Locale: duplicate key -> \(locale.$name)")
                    throw LocaleControllerError.unableToCreateNewRecord
                }
                logger.error("Create Locale: error -> \($0.localizedDescription)")
                throw $0
            }
            .flatMap {
                return locale.countries
                    .map { country in
                        return createLink(countryId: country.id, localeId: locale.id!)
                    }
                    .flatten(on: database.eventLoop)
            }
    }
    
    public func createLink(countryId: UUID?, localeId: UUID) -> Future<Void> {
        if let _ = countryId {
            return CountryLocale(id: UUID(), countryId: countryId!, localeId: localeId)
                .create(on: database)
        }
        return database.eventLoop.makeSucceededVoidFuture()
    }
    
    public func delete(id: UUID) -> Future<Void> {
        return LocaleModel
            .query(on: database)
            .filter(\.$id == id)
            .delete()
    }
    
    public func all() -> Future<[LocaleModel]> {
        return LocaleModel
            .query(on: database)
            .all()
    }
    
    public func find(id: UUID?) -> Future<LocaleModel?> {
        return LocaleModel
            .find(id, on: database)
    }
    
    public func find(identifier: String) -> Future<LocaleModel?> {
        return LocaleModel
            .query(on: database)
            .filter(\.$identifier == identifier)
            .first()
    }
    
    public func find(description: String) -> Future<LocaleModel?> {
        return LocaleModel
            .query(on: database)
            .filter(\.$description == description)
            .first()
    }
    
    public func set(_ locale: LocaleModel) -> Future<Void> {
        return LocaleModel
            .query(on: database)
            .filter(\.$id == locale.id!)
            .set(\.$description, to: locale.description)
            .set(\.$identifier, to: locale.identifier)
            .set(\.$dateSeparator, to: locale.dateSeparator)
            .set(\.$dateSequence, to: locale.dateSequence)
            .set(\.$language.$id, to: locale.language.id!)
            .set(\.$longName, to: locale.longName)
            .set(\.$standardDateSequence, to: locale.standardDateSequence)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<LocaleModel, Field>, to value: Field.Value, for localeID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LocaleModel
    {
        return LocaleModel
            .query(on: database)
            .filter(\.$id == localeID)
            .set(field, to: value)
            .update()
    }
    
    public func count() -> Future<Int> {
        return LocaleModel
            .query(on: database)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var locales: LocaleRepositoryProtocol {
        guard let storage = storage.makeLocaleRepository else {
            fatalError("LocaleRepository not configured, use: app.localeRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (LocaleRepositoryProtocol)) {
        storage.makeLocaleRepository = make
    }
}

