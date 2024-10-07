//
//  LanguageRepositoryMock.swift
//  
//
//  Created by Thomas Benninghaus on 25.05.24.
//

import Vapor
import Fluent
import DTO

public class LanguageRepositoryMock: LanguageRepositoryProtocol, TestRepositoryProtocol {
    private var database: BasicDataModels
    public var eventLoop: EventLoop
    
    public init(database: BasicDataModels? = nil, eventLoop: EventLoop) {
        self.database = database ?? BasicDataModels(user: nil, countries: [], locations: [], locales: [], countryLocales: [], languages: nil, localizations: [], keywords: [])
        self.eventLoop = eventLoop
    }
    
    public func create(_ language: LanguageModel) -> Future<Void> {
        database.languages.append(language)
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func delete(id: UUID) -> Future<Void> {
        database.languages.removeAll(where: { $0.id == id })
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func all() -> Future<[LanguageModel]> {
        return eventLoop.makeSucceededFuture(database.languages)
    }
    
    public func find(id: UUID?) -> Future<LanguageModel?> {
        let language = database.languages.first(where: { $0.id == id })
        return eventLoop.makeSucceededFuture(language)
    }
    
    public func find(identifier: LanguageIdentifier) -> Future<LanguageModel?> {
        let language = database.languages.first(where: { $0.identifier == identifier })
        return eventLoop.makeSucceededFuture(language)
    }
    
    public func find(name: String) -> Future<LanguageModel?> {
        let language = database.languages.first(where: { $0.name == name })
        return eventLoop.makeSucceededFuture(language)
    }
    
    public func set(_ language: LanguageModel) -> Future<Void> {
        let language = database.languages.first(where: { $0.id == language.id })!
        language[keyPath: \.$identifier].value = language.identifier
        language[keyPath: \.$name].value = language.name
        language[keyPath: \.$longName].value = language.longName
        return eventLoop.makeSucceededFuture(())
    }
    
    public func set<Field>(_ field: KeyPath<LanguageModel, Field>, to value: Field.Value, for languageID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LanguageModel
    {
        let language = database.languages.first(where: { $0.id == languageID })!
        language[keyPath: field].value = value
        return eventLoop.makeSucceededFuture(())
    }
    
    public func count() -> Future<Int> {
        return eventLoop.makeSucceededFuture(database.languages.count)
    }
}

