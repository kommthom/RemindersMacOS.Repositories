//
//  LocationRepositoryMock.swift
//  
//
//  Created by Thomas Benninghaus on 25.05.24.
//

import Vapor
import Fluent
import DTO

public class LocationRepositoryMock: LocationRepositoryProtocol, TestRepositoryProtocol {
    private var database: BasicDataModels
    public var eventLoop: EventLoop
    
    public init(database: BasicDataModels? = nil, eventLoop: EventLoop) {
        self.database = database ?? BasicDataModels(user: nil, countries: [], locations: nil, locales: [], countryLocales: [], languages: [], localizations: [], keywords: [])
        self.eventLoop = eventLoop
    }
    
    public func create(_ location: LocationModel) -> Future<Void> {
        database.locations.append(location)
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func delete(id: UUID) -> Future<Void> {
        database.locations.removeAll(where: { $0.id == id })
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func all() -> Future<[LocationModel]> {
        return eventLoop.makeSucceededFuture(database.locations)
    }
    
    public func find(id: UUID) -> Future<LocationModel?> {
        let location = database.locations.first(where: { $0.id == id })
        return eventLoop.makeSucceededFuture(location)
    }
    
    public func find(identifier: String) -> Future<LocationModel?> {
        let location = database.locations.first(where: { $0.identifier == identifier })
        return eventLoop.makeSucceededFuture(location)
    }
    
    public func find(countryId: UUID) -> Future<[LocationModel]> {
        let location = database.locations.filter({ $0.country.id == countryId })
        return eventLoop.makeSucceededFuture(location)
    }
    
    public func set(_ location: LocationModel) -> Future<Void> {
        let location = database.locations.first(where: { $0.id == location.id })!
        location[keyPath: \.$description].value = location.description
        location[keyPath: \.$identifier].value = location.identifier
        return eventLoop.makeSucceededFuture(())
    }
    
    public func set<Field>(_ field: KeyPath<LocationModel, Field>, to value: Field.Value, for locationID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LocationModel
    {
        let location = database.locations.first(where: { $0.id == locationID })!
        location[keyPath: field].value = value
        return eventLoop.makeSucceededFuture(())
    }
    
    public func count() -> Future<Int> {
        return eventLoop.makeSucceededFuture(database.locations.count)
    }
}

