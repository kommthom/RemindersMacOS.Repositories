//
//  UserRepositoryProtocol.swift
//
//
//  Created by Thomas Benninghaus on 11.12.23.
//

import Vapor
import Fluent

public protocol UserRepositoryProtocol: DBRepositoryProtocol {
    func create(_ user: UserModel) -> Future<Void>
    func delete(id: UUID, force: Bool) -> Future<Void>
    func all() -> Future<[UserModel]>
    func find(id: UUID?) -> Future<UserModel?>
    func find(email: String) -> Future<UserModel?>
    func set(_ user: UserModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<UserModel, Field>, to value: Field.Value, for userID: UUID) -> Future<Void> where Field: QueryableProperty, Field.Model == UserModel
    func count() -> Future<Int>
}

public protocol UserRepositoryMockProtocol {
    func createDemo(_ user: UserModel) -> Future<Void>
}
