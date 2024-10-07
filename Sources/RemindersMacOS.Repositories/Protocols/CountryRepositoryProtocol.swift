//
//  CountryRepositoryProtocol.swift
//
//
//  Created by Thomas Benninghaus on 18.05.24.
//

import Vapor
import Fluent
import DTO

public protocol CountryRepositoryProtocol: DBRepositoryProtocol {
    func create(_ country: CountryModel) -> Future<Void>
    func createLink(countryId: UUID?, localeId: UUID) -> Future<Void>
    func delete(id: UUID) -> Future<Void>
    func all() -> Future<[CountryModel]>
    func find(id: UUID?) -> Future<CountryModel?>
    func find(identifier: String) -> Future<CountryModel?>
    func set(_ country: CountryModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<CountryModel, Field>, to value: Field.Value, for countryID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == CountryModel
    func count(userId: UUID?) -> Future<Int>
}
