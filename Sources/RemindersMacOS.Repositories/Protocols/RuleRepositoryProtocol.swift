//
//  RuleRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 16.02.24.
//

import Vapor
import Fluent
import DTO

public protocol RuleRepositoryProtocol: DBRepositoryProtocol, RuleRepositoryMockProtocol {
    func create(_ rule: RuleModel, taskId: UUID?) -> Future<Void>
    func createIfNotExists(description: String, ruleType: RuleType, actionType: ActionType, args: [String]?, for userId: UUID, taskId: UUID?) -> Future<RuleModel>
    func createAll(userId: UUID) -> Future<Void>
    func delete(id: UUID, force: Bool) -> Future<Void>
    func all(userId: UUID?) -> Future<[RuleModel]>
    func allWithSelection(userId: UUID?, taskId: UUID?) -> Future<[(RuleModel, Bool)]>
    func find(id: UUID?) -> Future<RuleModel?>
    func find(userId: UUID?, description: String) -> Future<RuleModel?>
    func set(_ rule: RuleModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<RuleModel, Field>, to value: Field.Value, for ruleID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == RuleModel
    func setSelection(userId: UUID?, taskId: UUID?, ruleIds: [UUID]) -> Future<Void>
    func count(userId: UUID?) -> Future<Int>
}

public protocol RuleRepositoryMockProtocol {
    func getDemo(_ exampleNo: Int, userId: UUID) -> Future<[RuleModel]>
    func createDemo(_ exampleNo: Int, taskId: UUID, userId: UUID) -> Future<[RuleModel]>
}
