//
//  TaskRepositoryProtocol.swift
//
//
//  Created by Thomas Benninghaus on 23.12.23.
//

import Vapor
import Fluent

public protocol TaskRepositoryProtocol: DBRepositoryProtocol, TaskRepositoryMockProtocol {
    func create(_ task: TaskModel) -> Future<Void>
    func delete(id: UUID, force: Bool) -> Future<Void>
    func all(for projectId: ProjectModel.IDValue) -> Future<[TaskModel]>
    func overdue(userId: UUID) -> Future<[TaskModel]>
    func today(userId: UUID) -> Future<[TaskModel]>
    func soon(userId: UUID) -> Future<[TaskModel]>
    func byTag(tagId: TagModel.IDValue) -> Future<[TaskModel]>
    func find(id: UUID?) -> Future<TaskModel?>
    func find(project: UUID?, description: String) -> Future<[TaskModel]>
    func set(_  task: TaskModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<TaskModel, Field>, to value: Field.Value, for taskID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == TaskModel
    func setCompleted(_  taskId: TaskModel.IDValue, userId: UUID) -> Future<Void>
    func count(for project: ProjectModel) -> Future<Int>
}

public protocol TaskRepositoryMockProtocol: DBRepositoryProtocol {
    func getDemo(_ exampleNo: Int, projectId: UUID) -> [TaskModel]
    func createDemo(_ exampleNo: Int, projectId: UUID) -> Future<[(Int, TaskModel)]>
}
