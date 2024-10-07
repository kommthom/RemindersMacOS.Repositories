//
//  DatabaseHistoryRepository.swift
//
//
//  Created by Thomas Benninghaus on 28.01.24.
//

import Vapor
import Fluent

public struct DatabaseHistoryRepository: HistoryRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.history")
    
    public func create(_ history: HistoryModel) -> Future<Void> {
        logger.info("Create Status History: \(history.$historyType)")
        return history
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create History: duplicate key -> \(history.$timestamp)")
                    throw HistoryControllerError.unableToCreateNewRecord
                }
                logger.error("Create History: error -> \($0.localizedDescription)")
                throw $0
            }
    }
    
    public func delete(id: UUID) -> Future<Void> {
        return HistoryModel
            .query(on: database)
            .filter(\.$id == id)
            .delete()
    }
    
    public func all(for taskId: UUID?) -> Future<[HistoryModel]> {
        return HistoryModel
            .query(on: database)
            .filter(\.$task.$id == taskId!)
            .sort(\.$timestamp)
            .all()
    }
    
    public func find(id: UUID?) -> Future<HistoryModel?> {
        return HistoryModel
            .find(id, on: database)
    }
    
    public func set(_ history: HistoryModel) -> Future<Void> {
        return HistoryModel
            .query(on: database)
            .filter(\.$id == history.id!)
            .set(\.$historyType, to: history.historyType)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<HistoryModel, Field>, to value: Field.Value, for historyID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == HistoryModel
    {
        return HistoryModel
            .query(on: database)
            .filter(\.$id == historyID)
            .set(field, to: value)
            .update()
    }
    
    public func count() -> Future<Int> {
        return HistoryModel
            .query(on: database).count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var histories: HistoryRepositoryProtocol {
        guard let storage = storage.makeHistoryRepository else {
            fatalError("HistoryRepository not configured, use: app.historyRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (HistoryRepositoryProtocol)) {
        storage.makeHistoryRepository = make
    }
}
