//
//  TagRepositoryProtocol.swift
//
//
//  Created by Thomas Benninghaus on 27.01.24.
//

import Vapor
import Fluent
import DTO

public protocol TagRepositoryProtocol: DBRepositoryProtocol, TagRepositoryMockProtocol {
    func create(_ tag: TagModel, taskId: UUID?) -> Future<Void>
    func createLink(taskId: UUID?, tagId: UUID) -> Future<Void>
    func createIfNotExists(description: String, color: CodableColor?, for userId: UUID, taskId: UUID?) -> Future<TagModel>
    func createAll(userId: UUID) -> Future<Void>
    func delete(id: UUID, force: Bool) -> Future<Void>
    func all(userId: UUID?) -> Future<[TagModel]>
    func allWithSelection(userId: UUID?, taskId: UUID?) -> Future<[(TagModel, Bool)]>
    func find(id: UUID?) -> Future<TagModel?>
    func find(userId: UUID?, description: String) -> Future<TagModel?>
    func set(_ tag: TagModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<TagModel, Field>, to value: Field.Value, for tagID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == TagModel
    func setSelection(userId: UUID?, taskId: UUID?, tagIds: [UUID]) -> Future<Void>
    func count(userId: UUID?) -> Future<Int>
}

public protocol TagRepositoryMockProtocol {
    func getDemo(_ exampleNo: Int, userId: UUID) -> Future<[TagModel]>
    func createDemo(_ exampleNo: Int, taskId: UUID, userId: UUID) -> Future<[TagModel]>
}
