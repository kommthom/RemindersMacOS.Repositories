//
//  DatabaseUserSettingRepository.swift
//  
//
//  Created by Thomas Benninghaus on 30.01.24.
//

import Vapor
import Fluent
import DTO

public struct DatabaseUserSettingRepository: UserSettingRepositoryProtocol, DatabaseRepositoryProtocol {
    public let database: Database
    private let logger = Logger(label: "reminders.backend.settings")
    
    public func createAll(userId: UserModel.IDValue) -> Future<Void> {
        var settings: [SettingModel] = .init()
        settings.append(SettingModel(sortOrder: 1, scope: .sidebarOptionsType, name: "settings.show_count", description: "settings.show_count", valueType: .bool, boolValue: true, intValue: nil, stringValue: nil, idValue: nil, jsonValue: nil, userId: userId))
        settings.append(SettingModel(sortOrder: 2, scope: .sidebarType, name: "settings.inbox", description: "settings.inbox", valueType: .json, boolValue: true, intValue: nil, stringValue: "tasks/inbox", idValue: nil, jsonValue: nil, userId: userId))
        settings.append(SettingModel(sortOrder: 3, scope: .sidebarType, name: "settings.today", description: "settings.today", valueType: .string, boolValue: true, intValue: nil, stringValue: "tasks/today", idValue: nil, jsonValue: nil, userId: userId))
        settings.append(SettingModel(sortOrder: 4, scope: .sidebarType, name: "settings.soon", description: "settings.soon", valueType: .string, boolValue: true, intValue: nil, stringValue: "tasks/soon", idValue: nil, jsonValue: nil, userId: userId))
        settings.append(SettingModel(sortOrder: 5, scope: .sidebarType, name: "settings.filter", description: "settings.filter", valueType: .json, boolValue: true, intValue: nil, stringValue: nil, idValue: nil, jsonValue: "[]", userId: userId))
        settings.append(SettingModel(sortOrder: 6, scope: .sidebarType, name: "settings.labels", description: "settings.labels", valueType: .string, boolValue: true, intValue: nil, stringValue: "tags/index", idValue: nil, jsonValue: nil, userId: userId))
        settings.append(SettingModel(sortOrder: 7, scope: .sidebarType, name: "settings.done", description: "settings.done", valueType: .string, boolValue: true, intValue: nil, stringValue: "tasks/done", idValue: nil, jsonValue: nil, userId: userId))
        return settings
            .map { create( $0 ) }
            .flatten(on: database.eventLoop)
    }

    public func create(_ setting: SettingModel) -> Future<Void> {
        logger.info("Create Setting: \(setting.scope.rawValue)|\(setting.name)")
        return setting
            .create(on: database)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    logger.error("Create Setting: duplicate key -> \(setting.scope.rawValue)|\(setting.name)")
                    throw AuthenticationError.emailAlreadyExists
                }
                logger.error("Create Setting: error -> \($0.localizedDescription)")
                throw $0
            }
    }
    
    public func delete(id: UUID, force: Bool) -> Future<Void> {
        return SettingModel
            .query(on: database)
            .filter(\.$id == id)
            .delete(force: force)
    }
    
    public func all(userId: UUID?) -> Future<[SettingModel]> {
        return SettingModel
            .query(on: database)
            .join(UserModel.self, on: \TagModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .sort(\.$sortOrder, .ascending)
            .all()
    }
    
    public func all(userId: UUID?, type: ScopeType) -> Future<[SettingModel]> {
        return SettingModel
            .query(on: database)
            .join(UserModel.self, on: \TagModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .filter(SettingModel.self, \.$scope == type)
            .sort(\.$sortOrder, .ascending)
            .all()
    }
    
    public func sidebar(userId: UUID?) -> Future<[SettingModel]> {
        return SettingModel
            .query(on: database)
            .join(UserModel.self, on: \TagModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .filter(SettingModel.self, \.$scope == ScopeType.sidebarType)
            .filter(SettingModel.self, \.$boolValue == true)
            .all()
    }
    
    public func find(id: UUID?) -> Future<SettingModel?> {
        return SettingModel
            .find(id, on: database)
    }
    
    public func find(userId: UUID?, scope: ScopeType, name: String) -> Future<SettingModel?> {
        return SettingModel
            .query(on: database)
            .join(UserModel.self, on: \SettingModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .filter(SettingModel.self, \.$scope == scope)
            .filter(SettingModel.self, \.$name == name)
            .first()
    }
    
    public func all(userId: UUID?, scope: ScopeType) -> Future<[SettingModel]> {
        return SettingModel
            .query(on: database)
            .join(UserModel.self, on: \SettingModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .filter(SettingModel.self, \.$scope == scope)
            .all()
    }
    
    public func set(_ setting: SettingModel) -> Future<Void> {
        return SettingModel
            .query(on: database)
            .filter(\.$id == setting.id!)
            //.set(\.$valueType, to: setting.valueType)
            .set(\.$boolValue, to: setting.boolValue)
            .set(\.$intValue, to: setting.intValue)
            .set(\.$stringValue, to: setting.stringValue)
            .set(\.$idValue, to: setting.idValue)
            .set(\.$jsonValue, to: setting.jsonValue)
            .update()
    }
    
    public func set<Field>(_ field: KeyPath<SettingModel, Field>, to value: Field.Value, for settingID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == SettingModel
    {
        return SettingModel
            .query(on: database)
            .filter(\.$id == settingID)
            .set(field, to: value)
            .update()
    }
    
    public func count(userId: UUID?, scope: ScopeType) -> Future<Int> {
        return SettingModel
            .query(on: database)
            .join(UserModel.self, on: \SettingModel.$user.$id == \UserModel.$id)
            .filter(UserModel.self, \.$id == userId!)
            .filter(SettingModel.self, \.$scope == scope)
            .count()
    }
    
    public init(database: Database) {
        self.database = database
    }
}

extension Application.Repositories {
    public var settings: UserSettingRepositoryProtocol {
        guard let storage = storage.makeSettingRepository else {
            fatalError("SettingRepository not configured, use: app.settingRepository.use()")
        }
        
        return storage(app)
    }
    
    public func use(_ make: @escaping (Application) -> (UserSettingRepositoryProtocol)) {
        storage.makeSettingRepository = make
    }
}

