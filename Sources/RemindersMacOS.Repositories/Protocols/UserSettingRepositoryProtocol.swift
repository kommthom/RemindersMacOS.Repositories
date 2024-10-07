//
//  UserSettingRepositoryProtocol.swift
//
//
//  Created by Thomas Benninghaus on 30.01.24.
//

import Vapor
import Fluent
import DTO

public protocol UserSettingRepositoryProtocol: DBRepositoryProtocol {
    func create(_ setting: SettingModel) -> Future<Void>
    func createAll(userId: UserModel.IDValue) -> Future<Void>
    func delete(id: UUID, force: Bool) -> Future<Void>
    func all(userId: UUID?) -> Future<[SettingModel]>
    func all(userId: UUID?, type: ScopeType) -> Future<[SettingModel]>
    func sidebar(userId: UUID?) -> Future<[SettingModel]>
    func find(id: UUID?) -> Future<SettingModel?>
    func find(userId: UUID?, scope: ScopeType, name: String) -> Future<SettingModel?>
    func all(userId: UUID?, scope: ScopeType) -> Future<[SettingModel]>
    func set(_ setting: SettingModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<SettingModel, Field>, to value: Field.Value, for settingID: UUID) -> Future<Void>
        where Field: QueryableProperty, Field.Model == SettingModel
    func count(userId: UUID?, scope: ScopeType) -> Future<Int>
}

public protocol UserSettingRepositoryMockProtocol {
    func createDemo(userId: UserModel.IDValue) -> Future<Void>
}
