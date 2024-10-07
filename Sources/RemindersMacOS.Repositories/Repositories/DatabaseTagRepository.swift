//
//  DatabaseTagRepository.swift
//
//
//  Created by Thomas Benninghaus on 27.01.24.
//

import Vapor
import Fluent
import DTO

public struct DatabaseTagRepository: TagRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.tags")
    
    public func create(_ tag: TagModel, taskId: UUID? = nil) -> Future<Void> {
        logger.info("Create Tag: \(tag.$description)")
        return tag
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Tag: duplicate key -> \(tag.$description)")
                    throw TagControllerError.unableToCreateNewRecord
                }
                logger.error("Create Tag: error -> \($0.localizedDescription)")
                throw $0
            }
            .flatMap {
                return createLink(taskId: taskId, tagId: tag.id!)
            }
    }
    
    public func createLink(taskId: UUID?, tagId: UUID) -> Future<Void> {
        if let _ = taskId {
            return TaskTag(id: UUID(), taskId: taskId!, tagId: tagId)
                .create(on: database)
        }
        return database.eventLoop.makeSucceededVoidFuture()
    }
    
    public func createIfNotExists(description: String, color: CodableColor?, for userId: UUID, taskId: UUID? = nil) -> Future<TagModel> {
        return self.find(userId: userId, description: description)
            .flatMap { tag in
                if let _ = tag {
                    return createLink(taskId: taskId, tagId: tag!.id!)
                        .map { return tag! }
                } else {
                    let tag = TagModel(id: UUID(), description: description, color: color, for: userId)
                    return self
                        .create(tag, taskId: taskId)
                        .map { return tag }
                }
            }
    }
    
    public func createAll(userId: UUID) -> Future<Void> {
        var tags: [TagModel] = .init()
        tags.append(TagModel(id: UUID(), description: "tag.soon", color: CodableColor(wrappedValue: .blue), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.under_progress", color: CodableColor(wrappedValue: .brown), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.someday", color: CodableColor(wrappedValue: .cyan), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.waiting_for", color: CodableColor(wrappedValue: .darkGray), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.less_10min.", color: CodableColor(wrappedValue: .gray), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.weekend", color: CodableColor(wrappedValue: .green), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.next_steps.", color: CodableColor(wrappedValue: .lightGray), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.frequently", color: CodableColor(wrappedValue: .magenta), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.get_up", color: CodableColor(wrappedValue: .orange), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.banking", color: CodableColor(wrappedValue: .purple), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.shopping", color: CodableColor(wrappedValue: .red), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.hobby.", color: CodableColor(wrappedValue: .yellow), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.house", color: CodableColor(wrappedValue: .systemIndigo), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.reading.", color: CodableColor(wrappedValue: .systemMint), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.mac", color: CodableColor(wrappedValue: .systemPink), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.mobile", color: CodableColor(wrappedValue: .systemTeal), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.track", color: CodableColor(wrappedValue: .systemBlue), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.research", color: CodableColor(wrappedValue: .systemCyan), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.go_to_bed.", color: CodableColor(wrappedValue: .systemYellow), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.at_home", color: CodableColor(wrappedValue: .systemGreen), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.dinner.", color: CodableColor(wrappedValue: .systemRed), for: userId))
        tags.append(TagModel(id: UUID(), description: "tag.alexa", color: CodableColor(wrappedValue: .systemPurple), for: userId))
        return tags
            .map {
                create( $0 )
            }
            .flatten(on: database.eventLoop)
    }
    
    public func delete(id: UUID, force: Bool) -> Future<Void> {
        return TagModel
            .query(on: database)
            .filter(\.$id == id)
            .delete(force: force)
    }
    
    public func all(userId: UUID?) -> Future<[TagModel]> {
        return TagModel
            .query(on: database)
            .join(UserModel.self, on: \TagModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .all()
    }
    
    public func allWithSelection(userId: UUID?, taskId: UUID?) -> Future<[(TagModel, Bool)]> {
        return TagModel
            .query(on: database)
            .join(UserModel.self, on: \TagModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .sort(\.$description)
            .all()
            .flatMap { tags in
                tags
                    .map { tag in
                        TaskTag
                            .query(on: database)
                            .filter(\.$task.$id == taskId!)
                            .filter(\.$tag.$id == tag.id!)
                            .first()
                            .map { taskTag in
                                if let _ = taskTag {
                                    return (tag, true)
                                } else {
                                    return (tag, false)
                                }
                            }
                    }
                    .flatten(on: database.eventLoop)
            }
    }
    
    public func find(id: UUID?) -> Future<TagModel?> {
        return TagModel
            .find(id, on: database)
    }
    
    public func find(userId: UUID?, description: String) -> Future<TagModel?> {
        return TagModel
            .query(on: database)
            .join(UserModel.self, on: \TagModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .filter(TagModel.self, \.$description == description)
            .first()
    }
    
    public func set(_ tag: TagModel) -> Future<Void> {
        return TagModel
            .query(on: database)
            .filter(\.$id == tag.id!)
            .set(\.$description, to: tag.description)
            .set(\.$color, to: tag.color)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<TagModel, Field>, to value: Field.Value, for tagID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == TagModel
    {
        return TagModel
            .query(on: database)
            .filter(\.$id == tagID)
            .set(field, to: value)
            .update()
    }
    
    public func setSelection(userId: UUID?, taskId: UUID?, tagIds: [UUID]) -> Future<Void> {
        TaskTag
            .query(on: database)
            .filter(\.$task.$id == taskId!)
            .filter(\.$tag.$id !~ tagIds)
            .delete()
            .flatMap {
                return TaskTag
                    .query(on: database)
                    .filter(\.$task.$id == taskId!)
                    .filter(\.$tag.$id ~~ tagIds)
                    .all()
                    .map { existing in
                        return tagIds.compactMap { tagId in
                            if !existing.map({ $0.$tag.id }).contains( tagId ) {
                                return TaskTag(taskId: taskId!, tagId: tagId)
                            }
                            return nil
                        }
                    }
                    .flatMap { taskTags in
                        taskTags.create(on: database)
                    }
            }
    }
    
    public func count(userId: UUID?) -> Future<Int> {
        return TagModel
            .query(on: database)
            .join(UserModel.self, on: \TagModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var tags: TagRepositoryProtocol {
        guard let storage = storage.makeTagRepository else {
            fatalError("TagRepository not configured, use: app.tagRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (TagRepositoryProtocol)) {
        storage.makeTagRepository = make
    }
}
