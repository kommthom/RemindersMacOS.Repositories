//
//  LanguageRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 18.05.24.
//

import Vapor
import Fluent
import DTO

public protocol LanguageRepositoryProtocol: DBRepositoryProtocol {
    func create(_ languagee: LanguageModel) -> Future<Void>
    func delete(id: UUID) -> Future<Void>
    func all() -> Future<[LanguageModel]>
    func find(id: UUID?) -> Future<LanguageModel?>
    func find(identifier: LanguageIdentifier) -> Future<LanguageModel?>
    func find(name: String) -> Future<LanguageModel?>
    func set(_ language: LanguageModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<LanguageModel, Field>, to value: Field.Value, for languageID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LanguageModel
    func count() -> Future<Int>
}
