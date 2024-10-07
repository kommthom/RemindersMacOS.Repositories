//
//  ProjectRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 23.12.23.
//

import Vapor
import Fluent

public protocol ProjectRepositoryProtocol: DBRepositoryProtocol, ProjectRepositoryMockProtocol {
    func createRootIfNecessary(userId: UUID) -> Future<Void>
    func createArchiveIfNecessary(userId: UUID) -> Future<Void>
    func create(_ project: ProjectModel) -> Future<Void>
    func move(_ project: ProjectModel, lastChildOf: ProjectModel) -> Future<Void>
    func move(_ project: ProjectModel, leftOf: ProjectModel) -> Future<Void>
    func delete(id: UUID?, force: Bool) -> Future<Void>
    func delete(userId: UUID, leftKey: Int, rightKey: Int, force: Bool) -> Future<Void>
    func updatePaths(userId: UUID) -> Future<Void>
    func find(id: UUID?) -> Future<ProjectModel?>
    func find(userId: UUID, name: String) -> Future<ProjectModel?>
    func set(_  project: ProjectModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<ProjectModel, Field>, to value: Field.Value, for projectID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == ProjectModel
    func count(userId: UUID) -> Future<Int>
    func all(userId: UUID) -> Future<[ProjectModel]>
}

public protocol ProjectRepositoryMockProtocol {
    func getDemo(_ exampleNo: Int, userId: UUID, relativeKey: Int, defaultTagId: UUID?) -> ProjectModel
    func createDemoProjects(userId: UUID, defaultTagId: [UUID?]) -> Future<[ProjectModel]>
}
