//
//  InjectionKey.swift
//
//  Created by Chris Shireman on 5/14/25.
//

import Foundation

public protocol InjectionKey {
    /// The associated type representing the type of the dependency injection key's value.
    associatedtype Value: Sendable

    /// The default value for the dependency injection key.
    static var currentValue: Self.Value { get set }
}
