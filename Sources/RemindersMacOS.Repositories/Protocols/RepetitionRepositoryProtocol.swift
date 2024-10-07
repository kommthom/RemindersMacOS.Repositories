//
//  RepetitionRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 17.02.24.
//

import Vapor
import Fluent
import DTO

public protocol RepetitionRepositoryProtocol: DBRepositoryProtocol, RepetitionRepositoryMockProtocol {
    func create(_ repetition: RepetitionModel) -> Future<Void>
    func delete(id: UUID) -> Future<Void>
    func all(for taskId: UUID) -> Future<[RepetitionModel]>
    func find(id: UUID?) -> Future<RepetitionModel?>
    func set(_ repetition: RepetitionModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<RepetitionModel, Field>, to value: Field.Value, for repetitionID: UUID) -> Future<Void> where Field: QueryableProperty, Field.Model == RepetitionModel
    func count(for taskId: UUID) -> Future<Int>
}

public protocol RepetitionRepositoryMockProtocol {
    func getDemo(_ exampleNo: Int, locale: LocaleIdentifier, taskId: UUID, timePeriods: [TimePeriodModel]) -> RepetitionModel?
    func createDemo(_ exampleNo: Int, locale: LocaleIdentifier, taskId: UUID, timePeriods: [TimePeriodModel]) -> Future<RepetitionModel>
}
