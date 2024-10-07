//
//  DatabaseRepetitionRepository.swift
//  
//
//  Created by Thomas Benninghaus on 27.01.24.
//

import Vapor
import Fluent

public struct DatabaseRepetitionRepository: RepetitionRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend")
    
    public func create(_ repetition: RepetitionModel) -> Future<Void> {
        logger.info("Create Repetition: \(repetition.repetitionText)")
        return repetition
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Repetition: duplicate key -> \(repetition.repetitionText)")
                    throw AuthenticationError.emailAlreadyExists
                }
                logger.error("Create Repetition: error -> \($0.localizedDescription)")
                throw $0
            }
    }
    
    public func delete(id: UUID) -> Future<Void> {
        return RepetitionModel
            .query(on: database)
            .filter(\.$id == id)
            .delete()
    }
    
    public func all(for taskId: UUID) -> Future<[RepetitionModel]> {
        return RepetitionModel
            .query(on: database)
            .filter(\.$task.$id == taskId)
            .all()
    }
    
    public func find(id: UUID?) -> Future<RepetitionModel?> {
        return RepetitionModel
            .find(id, on: database)
    }
    
    public func set(_ repetition: RepetitionModel) -> Future<Void> {
        return RepetitionModel
            .query(on: database)
            .filter(\.$id == repetition.id!)
            .set(\.$repetitionNumber, to: repetition.repetitionNumber)
            .set(\.$repetitionJSON, to: repetition.repetitionJSON)
            .set(\.$repetitionEnd, to: repetition.repetitionEnd)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<RepetitionModel, Field>, to value: Field.Value, for repetitionID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == RepetitionModel
    {
        return RepetitionModel
            .query(on: database)
            .filter(\.$id == repetitionID)
            .set(field, to: value)
            .update()
    }
    
    public func count(for taskId: UUID) -> Future<Int> {
        return RepetitionModel
            .query(on: database)
            .filter(\.$task.$id == taskId)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var repetitions: RepetitionRepositoryProtocol {
        guard let storage = storage.makeRepetitionRepository else { fatalError("RepetitionRepository not configured, use: app.repetitionRepository.use()") }
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (RepetitionRepositoryProtocol)) {
        storage.makeRepetitionRepository = make
    }
}
