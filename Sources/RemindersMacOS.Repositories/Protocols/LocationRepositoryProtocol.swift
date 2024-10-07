//
//  LocationRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 18.05.24.
//

import Vapor
import Fluent

public protocol LocationRepositoryProtocol: DBRepositoryProtocol, LocationRepositoryMockProtocol {
    func create(_ location: LocationModel) -> Future<Void>
    func delete(id: UUID) -> Future<Void>
    func all() -> Future<[LocationModel]>
    func find(id: UUID) -> Future<LocationModel?>
    func find(identifier: String) -> Future<LocationModel?>
    func find(countryId: UUID) -> Future<[LocationModel]>
    func set(_ location: LocationModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<LocationModel, Field>, to value: Field.Value, for locationID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LocationModel
    func count() -> Future<Int>
}

public protocol LocationRepositoryMockProtocol {
}
