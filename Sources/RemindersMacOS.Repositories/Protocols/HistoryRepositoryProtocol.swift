//
//  HistoryRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 28.01.24.
//

import Vapor
import Fluent

public protocol HistoryRepositoryProtocol: DBRepositoryProtocol, HistoryRepositoryMockProtocol {
    func create(_ history: HistoryModel) -> Future<Void>
    func delete(id: UUID) -> Future<Void>
    func all(for taskId: UUID?) -> Future<[HistoryModel]>
    func find(id: UUID?) -> Future<HistoryModel?>
    func set(_ history: HistoryModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<HistoryModel, Field>, to value: Field.Value, for historyID: UUID) -> Future<Void> where Field: QueryableProperty, Field.Model == HistoryModel
    func count() -> Future<Int>
}

public protocol HistoryRepositoryMockProtocol {
    func getDemo(_ exampleNo: Int, taskId: UUID) -> [HistoryModel]
    func createDemo(_ exampleNo: Int, taskId: UUID, userId: UUID) -> Future<[HistoryModel]>
}
