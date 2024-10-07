//
//  DatabaseProjectRepository.swift
//  
//
//  Created by Thomas Benninghaus on 23.12.23.
//

import Vapor
import Fluent
import FluentSQL

public struct DatabaseProjectRepository: ProjectRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    
    public func createRootIfNecessary(userId: UUID) -> Future<Void> {
        return database
            .query(ProjectModel.self)
            .filter(\.$user.$id == userId)
            .filter(\.$leftKey == 1)
            .first()
            .flatMap { project in
                if let _ = project {
                    return database.eventLoop.makeSucceededFuture(())
                }
                return ProjectModel(userId: userId , leftKey: 1, rightKey: 2, name: Constants.projectsRootName, color: nil, isCompleted: false, level: 1, path: "/", isSystem: true)
                    .create(on: database)
            }
    }
    
    public func createArchiveIfNecessary(userId: UUID) -> Future<Void> {
        return database
            .query(ProjectModel.self)
            .filter(\.$user.$id == userId)
            .filter(\.$name == Constants.projectsArchiveName)
            .first()
            .flatMap { projectNil in
                if let _ = projectNil {
                    return database.eventLoop.makeSucceededFuture(())
                }
                return database
                    .query(ProjectModel.self)
                    .filter(\.$user.$id == userId)
                    .filter(\.$leftKey == 1)
                    .first()
                    .flatMap { project in
                        if let projectNotNil = project {
                            return create(ProjectModel(userId: userId, leftKey: projectNotNil.rightKey, rightKey: projectNotNil.rightKey + 1, name: Constants.projectsArchiveName, color: nil, isCompleted: false, level: 2, path: "/\(Constants.projectsArchiveName)/", isSystem: true))
                        }
                        return database.eventLoop.makeFailedFuture(ProjectControllerError.missingProject)
                    }
            }
    }
    
    private func updateRightKey(userId: UUID, rightKey: Int, increment: Int = 2, maxKey: Int = Int.max) -> Future<Void> {
        if let sql = database as? SQLDatabase {
            return sql
                .update("projects")
                .set("right", to: "right + \(increment)")
                .where("user_id", .equal, userId)
                .where("right", .greaterThanOrEqual, rightKey)
                .where("right", .lessThan, maxKey)
                .run()
        } else {
            // The underlying database driver is _not_ SQL.
            return database.eventLoop.makeFailedFuture(ConfigurationError.isNotSQLDatabase)
        }
    }
    
    private func updateLeftKey(userId: UUID, leftKey: Int, increment: Int = 2, maxKey: Int = Int.max) -> Future<Void> {
        if let sql = database as? SQLDatabase {
            return sql
                .update("projects")
                .set("left", to: "left + \(increment)")
                .where("user_id", .equal, userId)
                .where("left", .greaterThanOrEqual, leftKey)
                .where("left", .lessThan, maxKey)
                .run()
        } else {
            // The underlying database driver is _not_ SQL.
            return database.eventLoop.makeFailedFuture(ConfigurationError.isNotSQLDatabase)
        }
    }
    
    public func create(_ project: ProjectModel) -> Future<Void> {
        return updateLeftKey(userId: project.$user.id, leftKey: project.leftKey, increment: 1 + project.rightKey - project.leftKey)
            .flatMap {
                updateRightKey(userId: project.$user.id, rightKey: project.leftKey)
                    .flatMap {
                        project
                            .create(on: database)
                            .flatMap {
                                updatePaths(userId: project.$user.id)
                            }
                    }
            }
    }
    
    public func move(_ project: ProjectModel, lastChildOf: ProjectModel) -> Future<Void> {
        let swapValue: Int = 100000
        var nodeCount: Int = 1 + project.rightKey - project.leftKey
        var minKey: Int
        var maxKey: Int
        if project.leftKey < lastChildOf.leftKey {
            minKey = project.leftKey
            maxKey = lastChildOf.rightKey
            nodeCount = 0 - nodeCount
        } else {
            minKey = lastChildOf.rightKey
            maxKey = project.leftKey
        }
        let increment: Int = lastChildOf.rightKey - project.rightKey - 1
        return updateLeftKey(userId: project.$user.id, leftKey: project.leftKey, increment: swapValue, maxKey: project.rightKey)
            .flatMap() {
                updateRightKey(userId: project.$user.id, rightKey: project.leftKey, increment: swapValue, maxKey: project.rightKey)
                    .flatMap() {
                        updateLeftKey(userId: project.$user.id, leftKey: minKey, increment: nodeCount, maxKey: maxKey)
                            .flatMap() {
                                updateRightKey(userId: project.$user.id, rightKey: minKey, increment: nodeCount, maxKey: maxKey)
                                    .flatMap() {
                                        updateLeftKey(userId: project.$user.id, leftKey: project.leftKey + swapValue, increment: increment - swapValue)
                                            .flatMap() {
                                                updateRightKey(userId: project.$user.id, rightKey: project.leftKey + swapValue, increment: increment - swapValue)
                                                    .flatMap() {
                                                        updatePaths(userId: project.$user.id)
                                                    }
                                            }
                                    }
                            }
                    }
            }
    }
    
    public func move(_ project: ProjectModel, leftOf: ProjectModel) -> Future<Void> {
        let swapValue: Int = 100000
        var nodeCount: Int = 1 + project.rightKey - project.leftKey
        var minKey: Int
        var maxKey: Int
        if project.leftKey < leftOf.leftKey {
            minKey = project.leftKey
            maxKey = leftOf.leftKey - 1
            nodeCount = 0 - nodeCount
        } else {
            minKey = leftOf.leftKey
            maxKey = project.leftKey
        }
        let increment: Int = 1 + project.rightKey - leftOf.leftKey
        return updateLeftKey(userId: project.$user.id, leftKey: project.leftKey, increment: swapValue, maxKey: project.rightKey)
            .flatMap() {
                updateRightKey(userId: project.$user.id, rightKey: project.leftKey, increment: swapValue, maxKey: project.rightKey)
                    .flatMap() {
                        updateLeftKey(userId: project.$user.id, leftKey: minKey, increment: nodeCount, maxKey: maxKey)
                            .flatMap() {
                                updateRightKey(userId: project.$user.id, rightKey: minKey, increment: nodeCount, maxKey: maxKey)
                                    .flatMap() {
                                        updateLeftKey(userId: project.$user.id, leftKey: project.leftKey + swapValue, increment: increment - swapValue)
                                            .flatMap() {
                                                updateRightKey(userId: project.$user.id, rightKey: project.leftKey + swapValue, increment: increment - swapValue)
                                                    .flatMap() {
                                                        updatePaths(userId: project.$user.id)
                                                    }
                                            }
                                    }
                            }
                    }
            }
    }
    
    public func delete(id: UUID?, force: Bool = false) -> Future<Void> {
        return find(id: id)
            .flatMap() { project in
                if let deleteProject = project {
                    return delete(userId: deleteProject.$user.id, leftKey: deleteProject.leftKey, rightKey: deleteProject.rightKey, force: force)
                } else {
                    return database.eventLoop.makeFailedFuture(ProjectControllerError.missingProject)
                }
            }
    }
    
    public func delete(userId: UUID, leftKey: Int, rightKey: Int, force: Bool = false) -> Future<Void> {
        let increment = leftKey - rightKey - 1
        return ProjectModel
            .query(on: database)
            .filter(\.$leftKey >= leftKey)
            .filter(\.$rightKey <= rightKey)
            .delete(force: force)
            .flatMap {
                updateLeftKey(userId: userId, leftKey: leftKey, increment: increment)
                    .flatMap {
                        updateRightKey(userId: userId, rightKey: rightKey, increment: increment)
                            .flatMap {
                                updatePaths(userId: userId)
                            }
                    }
            }
    }

    public func all(userId: UUID) -> Future<[ProjectModel]> {
        /*let requestString: SQLQueryString = #"SELECT p1.id AS id, p1.left AS leftKey, p1.right AS rightKey, p1.name AS name, p1.color AS color, p1.iscompleted as isCompleted, p1.tagmodel_id AS defaultTagId, p1.repetition_id AS defaultRepetitionId, COUNT(p2.left) AS level, "" AS path FROM projects AS p1 LEFT JOIN projects as p2 ON p1.left BETWEEN p2.left AND p2.right GROUP BY p1.left ORDER BY p1.left "#
        */
        ProjectModel
            .query(on: database)
            .with(\.$items)
            .with(\.$defaultTag)
            .filter(\.$user.$id == userId)
            .filter(\.$isSystem == false)
            .sort("left")
            .all()
    }
    
    public func updatePaths(userId: UUID) -> Future<Void> {
        ProjectModel
            .query(on: database)
            .filter(\.$user.$id == userId)
            .all()
            .flatMapEach( on: database.eventLoop) { project in
                return self.updatePath(project: project)
            }
    }
    
    private func updatePath(project: ProjectModel) -> Future<Void> {
        return ProjectModel
            .query(on: database)
            .sort(\.$leftKey)
            .filter(\.$user.$id == project.$user.id)
            .filter(\.$leftKey <= project.leftKey)
            .filter(\.$rightKey >= project.rightKey)
            .all()
            .map() { projects in
                ("/\(projects.sorted(by: { $0.leftKey > $1.leftKey } ).map( { $0.name }).joined(separator: "/"))", projects.count)
            }
            .flatMap() { (path, level) in
                return ProjectModel.query(on: database)
                    .filter(\.$id == project.id!)
                    .set(\.$path, to: path)
                    .set(\.$level, to: level)
                    .update()
            }
    }
    
    public func find(id: UUID?) -> Future<ProjectModel?> {
        return ProjectModel
            .find(id, on: database)
    }
    
    public func find(userId: UUID, name: String) -> Future<ProjectModel?> {
        return ProjectModel
            .query(on: database)
            .with(\.$items)
            .with(\.$defaultTag)
            .filter(\.$user.$id == userId)
            .filter(\.$name == name)
            .first()
    }
    
    public func set(_  project: ProjectModel) -> Future<Void> {
        return ProjectModel
            .query(on: database)
            .filter(\.$id == project.id!)
            .set(\.$name, to: project.name)
            .set(\.$color, to: project.color)
            .set(\.$isCompleted, to: project.isCompleted)
            //.set(\.$defaultTag, to: project.defaultTag)
            //.set(\.$defaultRepetition, to: project.defaultRepetition)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<ProjectModel, Field>, to value: Field.Value, for projectID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == ProjectModel {
        return ProjectModel
                .query(on: database)
                .filter(\.$id == projectID)
                .set(field, to: value)
                .update()
    }
    
    public func count(userId: UUID) -> Future<Int> {
        return ProjectModel
            .query(on: database)
            .filter(\.$user.$id == userId)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var projects: ProjectRepositoryProtocol {
        guard let storage = storage.makeProjectRepository else {
            fatalError("ProjectRepository not configured, use: app.projectRepository.use()")
        }
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (ProjectRepositoryProtocol)) {
        storage.makeProjectRepository = make
    }
}
