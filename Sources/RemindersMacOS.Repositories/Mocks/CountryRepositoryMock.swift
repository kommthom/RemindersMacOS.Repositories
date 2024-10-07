//
//  CountryRepositoryMock.swift
//
//
//  Created by Thomas Benninghaus on 25.05.24.
//

import Vapor
import Fluent
import DTO

public class CountryRepositoryMock: CountryRepositoryProtocol, TestRepositoryProtocol {
    private var database: BasicDataModels
    public var eventLoop: EventLoop
    
    public init(database: BasicDataModels? = nil, eventLoop: EventLoop) {
        self.database = database ?? BasicDataModels(user: nil, countries: nil, locations: [], locales: [], countryLocales: nil, languages: [], localizations: [], keywords: [])
        self.eventLoop = eventLoop
    }
    
    public func create(_ country: CountryModel) -> Future<Void> {
        database.countries.append(country)
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func createLink(countryId: UUID?, localeId: UUID) -> Future<Void> {
        if let _ = countryId {
            database.countryLocales.append(CountryLocale(id: UUID(), countryId: countryId!, localeId: localeId))
        }
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func delete(id: UUID) -> Future<Void> {
        database.countryLocales.removeAll(where: { $0.country.id == id })
        database.countries.removeAll(where: { $0.id == id })
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func all() -> Future<[CountryModel]> {
        return eventLoop.makeSucceededFuture(database.countries)
    }
    
    public func find(id: UUID?) -> Future<CountryModel?> {
        let country = database.countries.first(where: { $0.id == id })
        return eventLoop.makeSucceededFuture(country)
    }
    
    public func find(identifier: String) -> Future<CountryModel?> {
        let country = database.countries.first(where: { $0.identifier == identifier })
        return eventLoop.makeSucceededFuture(country)
    }
    
    public func set(_ country: CountryModel) -> Future<Void> {
        let country = database.countries.first(where: { $0.id == country.id })!
        country[keyPath: \.$description].value = country.description
        country[keyPath: \.$identifier].value = country.identifier
        return eventLoop.makeSucceededFuture(())
    }
    
    public func set<Field>(_ field: KeyPath<CountryModel, Field>, to value: Field.Value, for countryID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == CountryModel
    {
        let country = database.countries.first(where: { $0.id == countryID })!
        country[keyPath: field].value = value
        return eventLoop.makeSucceededFuture(())
    }
    
    public func count(userId: UUID?) -> Future<Int> {
        return eventLoop.makeSucceededFuture(database.countries.count)
    }
}
