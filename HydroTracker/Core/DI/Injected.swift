//
//  Injected.swift
//
//  Created by Chris Shireman on 5/14/25.
//

import Foundation

@propertyWrapper @MainActor
struct Injected<T: Sendable> {
    private let keyPath: WritableKeyPath<InjectedValues, T>
    var wrappedValue: T {
        get {
            InjectedValues[keyPath]
        }
        set {
            InjectedValues[keyPath] = newValue
        }
    }
    
    init(_ keyPath: WritableKeyPath<InjectedValues, T>) {
        self.keyPath = keyPath
    }
}
