//
//  LocalizationRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 14.05.24.
//

//import Vapor
//import Fluent
//import DTO

public protocol LocalizationRepositoryProtocol: DBRepositoryProtocol {
    func create(_ localization: LocalizationModel) -> Future<Void>
    func create(_ localizations: [LocalizationModel]) -> Future<Void>
    func delete(id: UUID?, force: Bool) -> Future<Void>
    func find(id: UUID?) -> Future<LocalizationModel?>
    func find(userName: String, locale: String, key: String) -> Future<LocalizationModel?>
    func find(locale: String, key: KeyWord) -> Future<LocalizationModel?>
    func find(locale: String, enumKey: Int) -> Future<LocalizationModel?>
    func set(_  localization: LocalizationModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<LocalizationModel, Field>, to value: Field.Value, for localizationID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LocalizationModel
    func allLocales() -> Future<[String]>
    func all() -> Future<[LocalizationModel]>
    func all(locale: String) -> Future<[LocalizationModel]>
    func allKeyWords() -> Future<[LocalizationModel]>
}
