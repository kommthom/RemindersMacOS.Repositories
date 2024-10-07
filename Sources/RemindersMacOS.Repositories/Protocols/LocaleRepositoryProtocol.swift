//
//  LocaleRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 18.05.24.
//

import Vapor
import Fluent
import DTO

public protocol LocaleRepositoryProtocol: DBRepositoryProtocol {
    func create(_ locale: LocaleModel) -> Future<Void>
    func createLink(countryId: UUID?, localeId: UUID) -> Future<Void>
    func delete(id: UUID) -> Future<Void>
    func all() -> Future<[LocaleModel]>
    func find(id: UUID?) -> Future<LocaleModel?>
    func find(identifier: LocaleIdentifier) -> Future<LocaleModel?>
    func find(name: String) -> Future<LocaleModel?>
    func set(_ locale: LocaleModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<LocaleModel, Field>, to value: Field.Value, for localeID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LocaleModel
    func count() -> Future<Int>
}
