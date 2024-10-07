//
//  DatabaseUserRepository.swift
//  
//
//  Created by Thomas Benninghaus on 22.12.23.
//

import Vapor
import Fluent

public struct DatabaseUserRepository: UserRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend")
    
    private func createRelated(_ user: UserModel) -> Future<Void> {
        let settingRepository = DatabaseUserSettingRepository(database: database)
        let tagRepository = DatabaseTagRepository(database: database)
        let projectRepository = DatabaseProjectRepository(database: database)
        let timePeriodRepository = DatabaseTimePeriodRepository(database: database)
        let ruleRepository = DatabaseRuleRepository(database: database)
        return tagRepository.createAll(userId: user.id!)
            .flatMap {
                projectRepository
                    .createRootIfNecessary(userId: user.id!)
                    .flatMap {
                        projectRepository
                            .createArchiveIfNecessary(userId: user.id!)
                            .flatMap {
                                settingRepository
                                    .createAll(userId: user.id!)
                                    .flatMap {
                                        timePeriodRepository
                                            .createAll(userId: user.id!)
                                            .flatMap {
                                                ruleRepository
                                                    .createAll(userId: user.id!)
                                            }
                                    }
                            }
                    }
            }
    }
    
    public func create(_ user: UserModel) -> Future<Void> {
        logger.info("Create User: \(user.email)|\(user.passwordHash)")
        return user
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create User: duplicate key -> \(user.email)")
                    throw AuthenticationError.emailAlreadyExists
                }
                logger.error("Create User: error -> \($0.localizedDescription)")
                throw $0
            }
            .flatMap {
                createRelated(user)
            }
    }
    
    public func delete(id: UUID, force: Bool) -> Future<Void> {
        return UserModel
            .query(on: database)
            .filter(\.$id == id)
            .delete(force: force)
    }
    
    public func all() -> Future<[UserModel]> {
        return UserModel
            .query(on: database)
            .all()
    }
    
    public func find(id: UUID?) -> Future<UserModel?> {
        return UserModel
            .find(id, on: database)
    }
    
    public func find(email: String) -> Future<UserModel?> {
        return UserModel
            .query(on: database)
            .filter(\.$email == email)
            .first()
    }
    
    public func set(_ user: UserModel) -> Future<Void> {
        return UserModel
            .query(on: database)
            .filter(\.$id == user.id!)
            .set(\.$fullName, to: user.fullName)
            .set(\.$email, to: user.email)
            .set(\.$isAdmin, to: user.isAdmin)
            .set(\.$imageURL, to: user.imageURL)
            .set(\.$isEmailVerified, to: user.isEmailVerified)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<UserModel, Field>, to value: Field.Value, for userID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == UserModel
    {
        return UserModel
            .query(on: database)
            .filter(\.$id == userID)
            .set(field, to: value)
            .update()
    }
    
    public func count() -> Future<Int> {
        return UserModel
            .query(on: database)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var users: UserRepositoryProtocol {
        guard let storage = storage.makeUserRepository else {
            fatalError("UserRepository not configured, use: app.userRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (UserRepositoryProtocol)) {
        storage.makeUserRepository = make
    }
}
