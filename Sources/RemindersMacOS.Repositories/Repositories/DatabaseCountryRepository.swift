//
//  DatabaseCountryRepository.swift
//
//
//  Created by Thomas Benninghaus on 18.05.24.
//

import Vapor
import Fluent
import DTO

public struct DatabaseCountryRepository: CountryRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.countries")
    
    public func create(_ country: CountryModel) -> Future<Void> {
        logger.info("Create Country: \(country.$description)")
        return country
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Country: duplicate key -> \(country.$description)")
                    throw CountryControllerError.unableToCreateNewRecord
                }
                logger.error("Create Country: error -> \($0.localizedDescription)")
                throw $0
            }
            .flatMap {
                return country.locales
                    .map { locale in
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
        return CountryModel
            .query(on: database)
            .filter(\.$id == id)
            .delete()
    }
    
    public func all() -> Future<[CountryModel]> {
        return CountryModel
            .query(on: database)
            .with(\.$locales)
            .with(\.$locations)
            .all()
    }
    
    public func find(id: UUID?) -> Future<CountryModel?> {
        return CountryModel
            .find(id, on: database)
    }
    
    public func find(identifier: String) -> Future<CountryModel?> {
        return CountryModel
            .query(on: database)
            .filter(\.$identifier == identifier)
            .first()
    }
    
    public func set(_ country: CountryModel) -> Future<Void> {
        return CountryModel
            .query(on: database)
            .filter(\.$id == country.id!)
            .set(\.$description, to: country.description)
            .set(\.$identifier, to: country.identifier)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<CountryModel, Field>, to value: Field.Value, for countryID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == CountryModel
    {
        return CountryModel
            .query(on: database)
            .filter(\.$id == countryID)
            .set(field, to: value)
            .update()
    }
    
    public func count(userId: UUID?) -> Future<Int> {
        return CountryModel
            .query(on: database)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var countries: CountryRepositoryProtocol {
        guard let storage = storage.makeCountryRepository else {
            fatalError("CountryRepository not configured, use: app.countryRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (CountryRepositoryProtocol)) {
        storage.makeCountryRepository = make
    }
}
