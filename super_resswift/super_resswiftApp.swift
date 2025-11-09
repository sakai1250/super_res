//
//  super_resswiftApp.swift
//  super_resswift
//
//  Created by 坂井泰吾 on 2025/11/10.
//

import SwiftUI

@main
struct super_resswiftApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
