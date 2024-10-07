//
//  DatabaseRuleRepository.swift
//
//
//  Created by Thomas Benninghaus on 16.02.24.
//

import Vapor
import Fluent
import DTO

public struct DatabaseRuleRepository: RuleRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.rules")
    
    public func create(_ rule: RuleModel, taskId: UUID? = nil) -> Future<Void> {
        logger.info("Create Rule: \(rule.$description)")
        return rule
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Rule: duplicate key -> \(rule.$description)")
                    throw RuleControllerError.unableToCreateNewRecord
                }
                logger.error("Create Rule: error -> \($0.localizedDescription)")
                throw $0
            }
            .flatMap {
                return createLink(taskId: taskId, ruleId: rule.id!)
            }
    }
    
    public func createLink(taskId: UUID?, ruleId: UUID) -> Future<Void> {
        if let _ = taskId {
            return TaskRule(id: UUID(), taskId: taskId!, ruleId: ruleId)
                .create(on: database)
        }
        return database.eventLoop.makeSucceededVoidFuture()
    }
    
    public func createIfNotExists(description: String, ruleType: RuleType, actionType: ActionType, args: [String]? = nil, for userId: UUID, taskId: UUID? = nil) -> Future<RuleModel> {
        return self.find(userId: userId, description: description)
            .flatMap { rule in
                if let _ = rule {
                    return createLink(taskId: taskId, ruleId: rule!.id!)
                        .map { return rule! }
                } else {
                    let rule = RuleModel(id: UUID(), description: description, ruleType: ruleType, actionType: actionType, args: args, for: userId)
                    return self
                        .create(rule, taskId: taskId)
                        .map { return rule }
                }
            }
    }
    
    public func createAll(userId: UUID) -> Future<Void> {
        var rules: [RuleModel] = .init()
        rules.append(RuleModel(id: UUID(), description: "rule.archivewhencompleted", ruleType: .onEnd, actionType: .archive, for: userId))
        rules.append(RuleModel(id: UUID(), description: "rule.createnewwhencompleted", ruleType: .onEnd, actionType: .createTask, for: userId))
        rules.append(RuleModel(id: UUID(), description: "rule.opencalendarwhenstarted", ruleType: .onStart, actionType: .openCalendar, for: userId))
        rules.append(RuleModel(id: UUID(), description: "rule.openmailwhenstarted", ruleType: .onStart, actionType: .openMail, for: userId))
        rules.append(RuleModel(id: UUID(), description: "rule.openmusicwhenstarted", ruleType: .onStart, actionType: .openMusic, for: userId))
        rules.append(RuleModel(id: UUID(), description: "rule.readmetalhammerwhendue", ruleType: .onDue, actionType: .metalHammer, for: userId))
        return rules
            .map { create( $0 ) }
            .flatten(on: database.eventLoop)
    }
    
    public func delete(id: UUID, force: Bool) -> Future<Void> {
        return RuleModel
            .query(on: database)
            .filter(\.$id == id)
            .delete(force: force)
    }
    
    public func all(userId: UUID?) -> Future<[RuleModel]> {
        return RuleModel
            .query(on: database)
            .join(UserModel.self, on: \RuleModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .all()
    }
    
    public func allWithSelection(userId: UUID?, taskId: UUID?) -> Future<[(RuleModel, Bool)]> {
        return RuleModel
            .query(on: database)
            .join(UserModel.self, on: \RuleModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .sort(\.$description)
            .all()
            .flatMap { rules in
                rules
                    .map { rule in
                        TaskRule
                            .query(on: database)
                            .filter(\.$task.$id == taskId!)
                            .filter(\.$rule.$id == rule.id!)
                            .first()
                            .map { taskRule in
                                if let _ = taskRule { return (rule, true) } else { return (rule, false) }
                            }
                    }
                    .flatten(on: database.eventLoop)
            }
    }
    
    public func find(id: UUID?) -> Future<RuleModel?> {
        return RuleModel
            .find(id, on: database)
    }
    
    public func find(userId: UUID?, description: String) -> Future<RuleModel?> {
        return RuleModel
            .query(on: database)
            .join(UserModel.self, on: \RuleModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .filter(RuleModel.self, \.$description == description)
            .first()
    }
    
    public func set(_ rule: RuleModel) -> Future<Void> {
        return RuleModel
            .query(on: database)
            .filter(\.$id == rule.id!)
            .set(\.$description, to: rule.description)
            .set(\.$ruleType, to: rule.ruleType)
            .set(\.$actionType, to: rule.actionType)
            .set(\.$args, to: rule.args)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<RuleModel, Field>, to value: Field.Value, for ruleID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == RuleModel
    {
        return RuleModel
            .query(on: database)
            .filter(\.$id == ruleID)
            .set(field, to: value)
            .update()
    }
    
    public func setSelection(userId: UUID?, taskId: UUID?, ruleIds: [UUID]) -> Future<Void> {
        TaskRule
            .query(on: database)
            .filter(\.$task.$id == taskId!)
            .filter(\.$rule.$id !~ ruleIds)
            .delete()
            .flatMap {
                return TaskRule
                    .query(on: database)
                    .filter(\.$task.$id == taskId!)
                    .filter(\.$rule.$id ~~ ruleIds)
                    .all()
                    .map { existing in
                        return ruleIds.compactMap { ruleId in
                            if !existing.map({ $0.$rule.id }).contains( ruleId ) {
                                return TaskRule(taskId: taskId!, ruleId: ruleId)
                            }
                            return nil
                        }
                    }
                    .flatMap { taskRules in
                        taskRules.create(on: database)
                    }
            }
    }
    
    public func count(userId: UUID?) -> Future<Int> {
        return RuleModel
            .query(on: database)
            .join(UserModel.self, on: \RuleModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var rules: RuleRepositoryProtocol {
        guard let storage = storage.makeRuleRepository else {
            fatalError("RuleRepository not configured, use: app.ruleRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (RuleRepositoryProtocol)) {
        storage.makeRuleRepository = make
    }
}
