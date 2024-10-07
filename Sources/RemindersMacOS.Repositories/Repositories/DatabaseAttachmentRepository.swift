//
//  DatabaseAttachmentRepository.swift
//  
//
//  Created by Thomas Benninghaus on 28.01.24.
//

import Vapor
import Fluent

public struct DatabaseAttachmentRepository: AttachmentRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.attachments")
    
    public func create(_ attachment: AttachmentModel) -> Future<Void> {
        logger.info("Create Attachment: \(attachment.$comment)")
        return attachment
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Attachment: duplicate key -> \(attachment.$comment)")
                    throw AttachmentControllerError.unableToCreateNewRecord
                }
                logger.error("Create Attachment: error -> \($0.localizedDescription)")
                throw $0
            }
    }
    
    public func delete(id: UUID) -> Future<Void> {
        return AttachmentModel
            .query(on: database)
            .filter(\.$id == id)
            .delete()
    }
    
    public func all(for taskId: UUID) -> Future<[AttachmentModel]> {
        return AttachmentModel
            .query(on: database)
            .filter(\.$task.$id == taskId)
            .all()
    }
    
    public func find(id: UUID?) -> Future<AttachmentModel?> {
        return AttachmentModel
            .find(id, on: database)
    }
    
    public func set(_ attachment: AttachmentModel) -> Future<Void> {
        return AttachmentModel
            .query(on: database)
            .filter(\.$id == attachment.id!)
            .set(\.$comment, to: attachment.comment)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<AttachmentModel, Field>, to value: Field.Value, for attachmentID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == AttachmentModel
    {
        return AttachmentModel
            .query(on: database)
            .filter(\.$id == attachmentID)
            .set(field, to: value)
            .update()
    }
    
    public func count(for taskId: UUID) -> Future<Int> {
        return AttachmentModel
            .query(on: database)
            .filter(\.$task.$id == taskId)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var attachments: AttachmentRepositoryProtocol {
        guard let storage = storage.makeAttachmentRepository else {
            fatalError("AttachmentRepository not configured, use: app.attachmentRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (AttachmentRepositoryProtocol)) {
        storage.makeAttachmentRepository = make
    }
}
