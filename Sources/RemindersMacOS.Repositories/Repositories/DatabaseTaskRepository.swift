//
//  DatabaseTaskRepository.swift
//
//
//  Created by Thomas Benninghaus on 23.12.23.
//

import Vapor
import Fluent
import DTO

public struct DatabaseTaskRepository: TaskRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    
    public func create(_ task: TaskModel) -> Future<Void> {
        return task.create(on: database)
    }
    
    public func delete(id: UUID, force: Bool = false) -> Future<Void> {
        return TaskModel
            .query(on: database)
            .filter(\.$id == id)
            .delete(force: force)
    }
    
    private func queryTaskModelWithChilds() -> QueryBuilder<TaskModel> {
        TaskModel
            .query(on: database)
            .with(\.$attachments) { attachment in
                attachment.with(\.$files)
            }
            .with(\.$repetition) { repetition in
                repetition.with(\.$timePeriods)
            }
            .with(\.$statusHistory)
            .with(\.$rules)
            .with(\.$tags)
    }
    
    public func all(for projectId: ProjectModel.IDValue) -> Future<[TaskModel]> {
        return queryTaskModelWithChilds()
            .filter(TaskModel.self, \.$project.$id == projectId)
            .sort(\.$createdAt, .ascending)
            .all()
    }
    
    public func overdue(userId: UUID) -> Future<[TaskModel]> {
        return queryTaskModelWithChilds()
            .join(ProjectModel.self, on: \ProjectModel.$id == \TaskModel.$project.$id)
            .join(RepetitionModel.self, on: \RepetitionModel.$id == \TaskModel.$project.$id)
            .filter(ProjectModel.self, \.$user.$id == userId)
            .filter(\.$archivedPath == nil)
            .filter(RepetitionModel.self, \.$dueDate < Date.today)
            .sort(RepetitionModel.self, \.$dueDate, .ascending)
            .all()
    }
          
    public func today(userId: UUID) -> Future<[TaskModel]> {
        return queryTaskModelWithChilds()
            .join(ProjectModel.self, on: \ProjectModel.$id == \TaskModel.$project.$id)
            .join(RepetitionModel.self, on: \RepetitionModel.$id == \TaskModel.$project.$id)
            .filter(ProjectModel.self, \.$user.$id == userId)
            .filter(\.$archivedPath == nil)
            .filter(RepetitionModel.self, \.$dueDate < Date.tomorrow)
            .filter(RepetitionModel.self, \.$dueDate >= Date.today)
            .sort(RepetitionModel.self, \.$dueDate, .ascending)
            .all()
    }
    
    public func soon(userId: UUID) -> Future<[TaskModel]> {
        return queryTaskModelWithChilds()
            .join(ProjectModel.self, on: \ProjectModel.$id == \TaskModel.$project.$id)
            .join(RepetitionModel.self, on: \RepetitionModel.$id == \TaskModel.$project.$id)
            .filter(ProjectModel.self, \.$user.$id == userId)
            .filter(\.$archivedPath == nil)
            //.group(.or) {
            //    $0.filter(\.$dueDate < today).filter(\.$dueDate >= tomorrow)
            //}
            .filter(RepetitionModel.self, \.$dueDate >= Date.tomorrow)
            .sort(RepetitionModel.self, \.$dueDate, .ascending)
            .all()
    }
    
    public func byTag(tagId: TagModel.IDValue) -> Future<[TaskModel]> {
        return queryTaskModelWithChilds()
            .join(TaskTag.self, on: \TaskTag.$task.$id == \TaskModel.$id)
            .join(ProjectModel.self, on: \ProjectModel.$id == \TaskModel.$project.$id)
            .filter(TaskTag.self, \.$tag.$id == tagId)
            .sort(ProjectModel.self, \.$path, .ascending)
            .sort(\.$createdAt, .ascending)
            .all()
    }
    
    public func find(id: UUID?) -> Future<TaskModel?> {
        return queryTaskModelWithChilds()
            //.find(id, on: database)
            .filter(\.$id == id!)
            .first()
    }
    
    public func find(project: UUID?, description: String) -> Future<[TaskModel]> {
        return queryTaskModelWithChilds()
            .filter(\.$project.$id == project!)
            .filter(\.$itemDescription == description)
            .all()
    }

    public func set(_  task: TaskModel) -> Future<Void> {
        return TaskModel
            .query(on: database)
            .filter(\.$id == task.id!)
            .set(\.$itemDescription, to: task.itemDescription)
            .set(\.$title, to: task.title)
            .set(\.$isCompleted, to: task.isCompleted)
            .set(\.$homepage, to: task.homepage)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<TaskModel, Field>, to value: Field.Value, for taskID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == TaskModel {
        return TaskModel
                .query(on: database)
                .filter(\.$id == taskID)
                .set(field, to: value)
                .update()
    }
    
    public func setCompleted(_  taskId: TaskModel.IDValue, userId: UUID) -> Future<Void> {
        return ProjectModel
            .query(on: database)
            .filter(\.$user.$id == userId)
            .filter(\.$name == Constants.projectsArchiveName)
            .first()
            .flatMap() { project in
                return TaskModel
                    .query(on: database)
                    .filter(\.$id == taskId)
                    .set(\.$isCompleted, to: true)
                    .set(\.$archivedPath, to: project?.path)
                    .set(\.$parentItem.$id, to: project?.id)
                    .update()
            }
    }
    
    public func count(for project: ProjectModel) -> Future<Int> {
        return TaskModel
            .query(on: database)
            .filter(\.$project.$id == project.id!)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var tasks: TaskRepositoryProtocol {
        guard let storage = storage.makeTaskRepository else {
            fatalError("TaskRepository not configured, use: app.taskRepository.use()")
        }
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (TaskRepositoryProtocol)) {
        storage.makeTaskRepository = make
    }
}
