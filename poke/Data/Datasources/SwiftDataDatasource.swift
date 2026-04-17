//
//  SwiftDataDatasource.swift
//  poke
//
//  Created by user on 06/03/2024.
//

import SwiftData

@Observable
class SwiftDataDatasource {

    var modelContainer: ModelContainer?

    private let crashReporting: CrashReportingServiceProtocol = DIContainer.shared.crashReportingService

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
        } catch {
            crashReporting.captureError(error, context: [
                "action": "swiftdata_fetch_all",
                "type": String(describing: T.self)
            ])
            return []
        }
    }

    func create<T: PersistentModel>(type: T.Type, model: T) {
        guard let modelContainer else { return }
        do {
            let modelContext = ModelContext(modelContainer)
            modelContext.insert(model)
            try modelContext.save()
        } catch {
            crashReporting.captureError(error, context: [
                "action": "swiftdata_create",
                "type": String(describing: T.self)
            ])
        }
    }

    func save<T: PersistentModel>(type: T.Type) {
        guard let modelContainer else { return }
        do {
            let modelContext = ModelContext(modelContainer)
            try modelContext.save()
        } catch {
            crashReporting.captureError(error, context: [
                "action": "swiftdata_save",
                "type": String(describing: T.self)
            ])
        }
    }

    func delete<T: PersistentModel>(type: T.Type, model: T) {
        guard let modelContainer else { return }
        let modelContext = ModelContext(modelContainer)
        modelContext.delete(model)
    }
}
