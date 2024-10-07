//
//  TimePeriodRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 17.02.24.
//

import Vapor
import Fluent
import DTO

public protocol TimePeriodRepositoryProtocol: DBRepositoryProtocol, TimePeriodRepositoryMockProtocol {
    func create(_ timePeriod: TimePeriodModel, repetitionId: UUID?) -> Future<Void>
    func createIfNotExists(typeOfTime: TypeOfTime, from: String, to: String, day: Date?, for userId: UUID, repetitionId: UUID?) -> Future<TimePeriodModel>
    func createLink(repetitionId: UUID?, timePeriodId: UUID) -> Future<Void>
    func createLinks(repetitionId: UUID, timePeriods: [TimePeriodModel]) -> Future<Void>
    func createAll(userId: UUID) -> Future<Void>
    func delete(id: UUID, force: Bool) -> Future<Void>
    func all(userId: UUID?) -> Future<[TimePeriodModel]>
    func allWithSelection(userId: UUID?, taskId: UUID?) -> Future<[(TimePeriodModel, Bool)]>
    func find(id: UUID?) -> Future<TimePeriodModel?>
    func getByTypes(userId: UUID?, typesOfTime: [TypeOfTime]) -> Future<[TimePeriodModel]>
    func find(userId: UUID?, typeOfTime: TypeOfTime, from: String, to: String) -> Future<TimePeriodModel?>
    func find(parentId: UUID?, day: Date?) -> Future<TimePeriodModel?>
    func set(_ timePeriod: TimePeriodModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<TimePeriodModel, Field>, to value: Field.Value, for timePeriodID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == TimePeriodModel
    func setSelection(userId: UUID?, taskId: UUID?, timePeriodIds: [UUID]) -> Future<Void>
    func count(userId: UUID?) -> Future<Int>
}

public protocol TimePeriodRepositoryMockProtocol {
    func getDemo(_ exampleNo: Int, userId: UUID) -> Future<[TimePeriodModel]>
    func createDemo(_ exampleNo: Int,
                           userId: UUID,
                           createRepetition: @escaping (_ timePeriods: [TimePeriodModel]) -> Future<RepetitionModel>
                          ) -> Future<[TimePeriodModel]>
}
