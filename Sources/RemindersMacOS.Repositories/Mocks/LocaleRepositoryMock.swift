//
//  LocaleRepositoryMock.swift
//  
//
//  Created by Thomas Benninghaus on 25.05.24.
//

import Vapor
import Fluent
import DTO

public class LocaleRepositoryMock: LocaleRepositoryProtocol, TestRepositoryProtocol {
    private var database: BasicDataModels
    public var eventLoop: EventLoop
    
    public init(database: BasicDataModels? = nil, eventLoop: EventLoop) {
        self.database = database ?? BasicDataModels(user: nil, countries: [], locations: [], locales: nil, countryLocales: nil, languages: [], localizations: [], keywords: [])
        self.eventLoop = eventLoop
    }
    
    public func create(_ locale: LocaleModel) -> Future<Void> {
        database.locales.append(locale)
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func createLink(countryId: UUID?, localeId: UUID) -> Future<Void> {
        if let _ = countryId {
            database.countryLocales.append(CountryLocale(id: UUID(), countryId: countryId!, localeId: localeId))
        }
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func delete(id: UUID) -> Future<Void> {
        database.countryLocales.removeAll(where: { $0.locale.id == id })
        database.locales.removeAll(where: { $0.id == id })
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func all() -> Future<[LocaleModel]> {
        return eventLoop.makeSucceededFuture(database.locales)
    }
    
    public func find(id: UUID?) -> Future<LocaleModel?> {
        let locale = database.locales.first(where: { $0.id == id })
        return eventLoop.makeSucceededFuture(locale)
    }
    
    public func find(identifier: LocaleIdentifier) -> Future<LocaleModel?> {
        let locale = database.locales.first(where: { $0.identifier == identifier })
        return eventLoop.makeSucceededFuture(locale)
    }
    
    public func find(name: String) -> Future<LocaleModel?> {
        let locale = database.locales.first(where: { $0.name == name })
        return eventLoop.makeSucceededFuture(locale)
    }
    
    public func set(_ locale: LocaleModel) -> Future<Void> {
        let locale = database.locales.first(where: { $0.id == locale.id })!
        locale[keyPath: \.$dateSeparator].value = locale.dateSeparator
        locale[keyPath: \.$dateSequence].value = locale.dateSequence
        locale[keyPath: \.$identifier].value = locale.identifier
        locale[keyPath: \.$longName].value = locale.longName
        locale[keyPath: \.$name].value = locale.name
        locale[keyPath: \.$standardDateSequence].value = locale.standardDateSequence
        return eventLoop.makeSucceededFuture(())
    }
    
    public func set<Field>(_ field: KeyPath<LocaleModel, Field>, to value: Field.Value, for localeID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == LocaleModel
    {
        let locale = database.locales.first(where: { $0.id == localeID })!
        locale[keyPath: field].value = value
        return eventLoop.makeSucceededFuture(())
    }
    
    public func count() -> Future<Int> {
        return eventLoop.makeSucceededFuture(database.locales.count)
    }
}

