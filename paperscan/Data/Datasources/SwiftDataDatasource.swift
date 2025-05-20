//
//  SwiftDataDatasource.swift
//  paperscan
//
//  Created by user on 06/03/2024.
//

import SwiftData

@Observable
class SwiftDataDatasource {

    var modelContainer: ModelContainer?

    @MainActor
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getAll<T: PersistentModel>(type: T.Type) -> [T] {
        guard let modelContainer else { return [] }
        do {
            let modelContext = ModelContext(modelContainer)
            let fetchDescriptor = FetchDescriptor<T>(sortBy: [])
            return try modelContext.fetch(fetchDescriptor)
        } catch let error {
            print(error)
            return []
        }
    }

    func create<T: PersistentModel>(type: T.Type, model: T) {
        guard let modelContainer else { return }
        do {
            let modelContext = ModelContext(modelContainer)
            modelContext.insert(model)
            try modelContext.save()
        } catch let error {
            print(error)
        }
    }

    func save<T: PersistentModel>(type: T.Type) {
        guard let modelContainer else { return }
        do {
            let modelContext = ModelContext(modelContainer)
            try modelContext.save()
        } catch let error {
            print(error)
        }
    }

    func delete<T: PersistentModel>(type: T.Type, model: T) {
        guard let modelContainer else { return }
        let modelContext = ModelContext(modelContainer)
        modelContext.delete(model)
    }
}
