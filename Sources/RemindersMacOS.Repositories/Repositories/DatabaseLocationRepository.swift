//
//  DatabaseLocationRepository.swift
//  
//
//  Created by Thomas Benninghaus on 18.05.24.
//

import Vapor
import Fluent

public struct DatabaseLocationRepository: LocationRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.countries")
    
    public func create(_ location: LocationModel) -> Future<Void> {
        logger.info("Create Location: \(location.$description)")
        return location
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Location: duplicate key -> \(location.$description)")
                    throw LocationControllerError.unableToCreateNewRecord
                }
                logger.error("Create Location: error -> \($0.localizedDescription)")
                throw $0
            }
    }
    
    public func delete(id: UUID) -> Future<Void> {
        return LocationModel
            .query(on: database)
            .filter(\.$id == id)
            .delete(force: true)
    }
    
    public func all() -> Future<[LocationModel]> {
        return LocationModel
            .query(on: database)
            .all()
    }
    
    public func find(id: UUID) -> Future<LocationModel?> {
        return LocationModel
            .find(id, on: database)
    }
    
    public func find(countryId: UUID) -> Future<[LocationModel]> {
        return LocationModel
            .query(on: database)
            .filter(\.$country.$id == countryId)
            .all()
    }
    
    public func find(identifier: String) -> Future<LocationModel?> {
        return LocationModel
            .query(on: database)
            .filter(\.$identifier == identifier)
            .first()
    }
    
    public func set(_ location: LocationModel) -> Future<Void> {
        return LocationModel
            .query(on: database)
            .filter(\.$id == location.id!)
            .set(\.$description, to: location.description)
            .set(\.$identifier, to: location.identifier)
            .set(\.$timeZone, to: location.timeZone)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<LocationModel, Field>, to value: Field.Value, for locationID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LocationModel
    {
        return LocationModel
            .query(on: database)
            .filter(\.$id == locationID)
            .set(field, to: value)
            .update()
    }
    
    public func count() -> Future<Int> {
        return LocationModel
            .query(on: database)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var locations: LocationRepositoryProtocol {
        guard let storage = storage.makeLocationRepository else {
            fatalError("LocationRepository not configured, use: app.locationRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (LocationRepositoryProtocol)) {
        storage.makeLocationRepository = make
    }
}

