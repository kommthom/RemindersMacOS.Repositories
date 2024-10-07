//
//  DatabaseTimePeriodRepository.swift
//
//
//  Created by Thomas Benninghaus on 17.02.24.
//

import Vapor
import Fluent
import DTO

public struct DatabaseTimePeriodRepository: TimePeriodRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.timePeriods")
    
    public func create(_ timePeriod: TimePeriodModel, repetitionId: UUID? = nil) -> Future<Void> {
        logger.info("Create TimePeriod: \(timePeriod.$from)")
        return timePeriod
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create TimePeriod: duplicate key -> \(timePeriod.$from)")
                    throw TimePeriodControllerError.unableToCreateNewRecord
                }
                logger.error("Create TimePeriod: error -> \($0.localizedDescription)")
                throw $0
            }
            .flatMap {
                return createLink(repetitionId: repetitionId, timePeriodId: timePeriod.id!)
            }
    }
    
    public func createLink(repetitionId: UUID?, timePeriodId: UUID) -> Future<Void> {
        if let _ = repetitionId {
            return RepetitionTimePeriod(id: UUID(), repetitionId: repetitionId!, timePeriodId: timePeriodId)
                .create(on: database)
        }
        return database.eventLoop.makeSucceededVoidFuture()
    }
    
    public func createLinks(repetitionId: UUID, timePeriods: [TimePeriodModel]) -> Future<Void> {
        timePeriods
            .compactMap { RepetitionTimePeriod(id: UUID(), repetitionId: repetitionId, timePeriodId: $0.id!) }
            .create(on: database)
    }
    
    public func createIfNotExists(typeOfTime: TypeOfTime, from: String, to: String, day: Date?, for userId: UUID, repetitionId: UUID? = nil) -> Future<TimePeriodModel> {
        return TimePeriodModel
                    .query(on: database)
                    .join(UserModel.self, on: \TimePeriodModel.$user.$id == \UserModel.$id)
                    .filter(UserModel.self, \.$id == userId)
                    .filter(\.$typeOfTime == typeOfTime)
                    .filter(\.$from == from)
                    .filter(\.$to == to)
                    .filter(\.$day == day)
                    .first()
                    .flatMap { timePeriod in
                        if let _ = timePeriod {
                            return self
                                .createLink(repetitionId: repetitionId, timePeriodId: timePeriod!.id!)
                                .map { return timePeriod! }
                        } else {
                            let timePeriod = TimePeriodModel(id: UUID(), typeOfTime: typeOfTime, from: from, to: to, day: day, parentId: nil, for: userId)
                            return self
                                .create(timePeriod, repetitionId: repetitionId)
                                .map { return timePeriod }
                        }
                    }
    }
    
    public func createAll(userId: UUID) -> Future<Void> {
        var timePeriods: [TimePeriodModel] = .init()
        timePeriods.append(TimePeriodModel(id: UUID(), typeOfTime: .sleepingTime, from: "23:30", to: "08:30", day: nil, parentId: nil, for: userId))
        timePeriods.append(TimePeriodModel(id: UUID(), typeOfTime: .normalWorkingTime, from: "10:00", to: "20:00", day: nil, parentId: nil, for: userId))
        timePeriods.append(TimePeriodModel(id: UUID(), typeOfTime: .normalLeisureTime, from: "20:00", to: "23:30", day: nil, parentId: nil, for: userId))
        timePeriods.append(TimePeriodModel(id: UUID(), typeOfTime: .normalLeisureTime, from: "08:30", to: "10:00", day: nil, parentId: nil, for: userId))
        timePeriods.append(TimePeriodModel(id: UUID(), typeOfTime: .normalLeisureTimeWE, from: "09:30", to: "23:30", day: nil, parentId: nil, for: userId))
        timePeriods.append(TimePeriodModel(id: UUID(), typeOfTime: .sleepingTimeWE, from: "23:30", to: "09:30", day: nil, parentId: nil, for: userId))
        
        return timePeriods
            .map { create( $0 ) }
            .flatten(on: database.eventLoop)
    }
    
    public func delete(id: UUID, force: Bool) -> Future<Void> {
        return TimePeriodModel
            .query(on: database)
            .filter(\.$id == id)
            .delete(force: force)
    }
    
    public func all(userId: UUID?) -> Future<[TimePeriodModel]> {
        return TimePeriodModel
            .query(on: database)
            .join(UserModel.self, on: \TimePeriodModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .all()
    }
    
    public func allWithSelection(userId: UUID?, taskId: UUID?) -> Future<[(TimePeriodModel, Bool)]> {
        return TimePeriodModel
            .query(on: database)
            .join(UserModel.self, on: \TimePeriodModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .sort(\.$from)
            .all()
            .flatMap { timePeriods in
                timePeriods
                    .map { timePeriod in
                        RepetitionTimePeriod
                            .query(on: database)
                            .join(RepetitionModel.self, on: \RepetitionTimePeriod.$repetition.$id == \RepetitionModel.$id)
                            .filter(RepetitionModel.self, \.$task.$id == taskId!)
                            .filter(\.$timePeriod.$id == timePeriod.id!)
                            .first()
                            .map { repetitionTimePeriod in
                                if let _ = repetitionTimePeriod {
                                    return (timePeriod, true)
                                } else {
                                    return (timePeriod, false)
                                }
                            }
                    }
                    .flatten(on: database.eventLoop)
            }
    }
    
    public func find(id: UUID?) -> Future<TimePeriodModel?> {
        return TimePeriodModel
            .find(id, on: database)
    }
    
    public func getByTypes(userId: UUID?, typesOfTime: [TypeOfTime]) -> Future<[TimePeriodModel]> {
        return TimePeriodModel
                    .query(on: database)
                    .join(UserModel.self, on: \TimePeriodModel.$user.$id == \UserModel.$id)
                    .filter(UserModel.self, \.$id == userId!)
                    .filter(\.$typeOfTime ~~ typesOfTime)
                    .all()
    }
    
    public func find(userId: UUID?, typeOfTime: TypeOfTime, from: String, to: String) -> Future<TimePeriodModel?> {
        return TimePeriodModel
                    .query(on: database)
                    .join(UserModel.self, on: \TimePeriodModel.$user.$id == \UserModel.$id)
                    .filter(UserModel.self, \.$id == userId!)
                    .filter(\.$typeOfTime == typeOfTime)
                    .filter(\.$from == from)
                    .filter(\.$to == to)
                    .first()
    }
    
    public func find(parentId: UUID?, day: Date?) -> Future<TimePeriodModel?> {
        return TimePeriodModel
            .query(on: database)
            .filter(\.$parent.$id == parentId)
            .filter(\.$day == day)
            .first()
    }
    
    public func set(_ timePeriod: TimePeriodModel) -> Future<Void> {
        return TimePeriodModel
            .query(on: database)
            .filter(\.$id == timePeriod.id!)
            .set(\.$typeOfTime, to: timePeriod.typeOfTime)
            .set(\.$from, to: timePeriod.from)
            .set(\.$to, to: timePeriod.to)
            .set(\.$day, to: timePeriod.day)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<TimePeriodModel, Field>, to value: Field.Value, for timePeriodID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == TimePeriodModel
    {
        return TimePeriodModel
            .query(on: database)
            .filter(\.$id == timePeriodID)
            .set(field, to: value)
            .update()
    }
    
    public func setSelection(userId: UUID?, taskId: UUID?, timePeriodIds: [UUID]) -> Future<Void> {
        RepetitionModel
            .query(on: database)
            .filter(\.$task.$id == taskId!) //task_id
            .all()
            .flatMap { repetitions in
                guard let repetition = repetitions.first else { return database.eventLoop.makeSucceededVoidFuture() }
                return RepetitionTimePeriod
                    .query(on: database)
                    .filter(\.$repetition.$id == repetition.id!)
                    .filter(\.$timePeriod.$id !~ timePeriodIds)
                    .delete()
                    .flatMap {
                        RepetitionTimePeriod
                            .query(on: database)
                            .filter(\.$repetition.$id == repetition.id!)
                            .filter(\.$timePeriod.$id ~~ timePeriodIds)
                            .all()
                            .map { existing in
                                timePeriodIds.compactMap { timePeriodId in
                                    if !existing.map({ $0.$timePeriod.id }).contains( timePeriodId ) {
                                        return RepetitionTimePeriod(repetitionId: repetition.id!, timePeriodId: timePeriodId)
                                    }
                                    return nil
                                }
                            }
                            .flatMap { repetitionTimePeriods in
                                repetitionTimePeriods.create(on: database)
                            }
                    }
           }
    }
    
    public func count(userId: UUID?) -> Future<Int> {
        return TimePeriodModel
            .query(on: database)
            .join(UserModel.self, on: \TimePeriodModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var timePeriods: TimePeriodRepositoryProtocol {
        guard let storage = storage.makeTimePeriodRepository else {
            fatalError("TimePeriodRepository not configured, use: app.timePeriodRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (TimePeriodRepositoryProtocol)) {
        storage.makeTimePeriodRepository = make
    }
}
