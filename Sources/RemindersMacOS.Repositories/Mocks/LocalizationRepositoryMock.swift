//
//  LocalizationRepositoryMock.swift
//
//
//  Created by Thomas Benninghaus on 25.05.24.
//

import Vapor
import Fluent
import DTO

public class LocalizationRepositoryMock: LocalizationRepositoryProtocol, TestRepositoryProtocol {
    private var database: BasicDataModels
    public var eventLoop: EventLoop
    
    public init(database: BasicDataModels? = nil, eventLoop: EventLoop) {
        self.database = database ?? BasicDataModels(user: nil, countries: [], locations: [], locales: [], countryLocales: nil, languages: [], localizations: nil, keywords: [])
        self.eventLoop = eventLoop
    }
    
    public func create(_ localization: LocalizationModel) -> Future<Void> {
        database.localizations.append(localization)
        return self.eventLoop.makeSucceededVoidFuture()
    }

    public func create(_ localizations: [LocalizationModel]) -> Future<Void> {
        database.localizations.append(contentsOf: localizations)
        return self.eventLoop.makeSucceededVoidFuture()
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
    
    public func delete(id: UUID?, force: Bool) -> Future<Void> {
        database.localizations.removeAll(where: { $0.id == id })
        return self.eventLoop.makeSucceededVoidFuture()
    }
    
    public func find(id: UUID?) -> Future<LocalizationModel?> {
        let localization = database.localizations.first(where: { $0.id == id })
        return eventLoop.makeSucceededFuture(localization)
    }
    
    public func find(userName: String, locale: String, key: String) -> Future<LocalizationModel?> {
        let localization = database.localizations.filter( { $0.key == key }).first(where: { $0.languageCode == userName || $0.languageCode == locale})
        return eventLoop.makeSucceededFuture(localization)
    }
    
    // find KeyWord
    public func find(locale: String, key: KeyWord) -> Future<LocalizationModel?> {
        let localization = database.localizations.filter( { $0.enumKey == key.rawValue }).first(where: { $0.languageCode == locale})
        return eventLoop.makeSucceededFuture(localization)
    }
    
    public func find(locale: String, enumKey: Int) -> Future<LocalizationModel?> {
        let localization = database.localizations.filter( { $0.enumKey == enumKey }).first(where: { $0.languageCode == locale})
        return eventLoop.makeSucceededFuture(localization)
    }
    
    public func set(_ localization: LocalizationModel) -> Future<Void> {
        let country = database.countries.first(where: { $0.id == localization.id })!
        localization[keyPath: \.$key].value = localization.key
        localization[keyPath: \.$value].value = localization.value
        localization[keyPath: \.$pluralized].value = localization.pluralized
        return eventLoop.makeSucceededFuture(())
    }
    
    public func set<Field>(_ field: KeyPath<LocalizationModel, Field>, to value: Field.Value, for localizationID: UUID) -> Future<Void> where Field : QueryableProperty, Field.Model == LocalizationModel {
        let localization = database.localizations.first(where: { $0.id == localizationID })!
        localization[keyPath: field].value = value
        return eventLoop.makeSucceededFuture(())
    }

    public func allLocales() -> Future<[String]> {
        return eventLoop.makeSucceededFuture(database.localizations.compactMap( { $0.languageCode } ).unique() )
    }
    
    public func all() -> Future<[LocalizationModel]> {
        return eventLoop.makeSucceededFuture(database.localizations)
    }
    
    public func all(locale: String) -> Future<[LocalizationModel]> {
        return eventLoop.makeSucceededFuture(database.localizations.filter( {
            $0.languageCode == locale && $0.enumKey == nil
        }) )
    }
    
    public func allKeyWords() -> Future<[LocalizationModel]> {
        return eventLoop.makeSucceededFuture(database.localizations.filter( {
            $0.enumKey != nil
        }) )
    }
}
