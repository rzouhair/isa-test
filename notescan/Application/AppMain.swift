import Foundation
import SwiftUI
import Firebase
import RevenueCat
import SwiftData

@main
struct AppMain: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    @State private var appState = AppState()
    
    private var provider = OpenAIProxiedProvider()
    @State private var aiService: AIService

    @State private var swiftDataDatasource: SwiftDataDatasource
    @State var modelContainer: ModelContainer
    
    private let functionsToRegister: [RegisterableFunction] = [
        ItemDetectionFunction.registerableFunction(),
        ItemValuationFunction.registerableFunction(),
        ItemRarityFunction.registerableFunction(),
        ItemGradeFunction.registerableFunction()
    ]
    
    @MainActor
    init() {
        
        let container: ModelContainer
        let schema = Schema([
            Banknote.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContainer = container
            swiftDataDatasource = SwiftDataDatasource(modelContainer: container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        FirebaseApp.configure()
        Purchases.configure(
            with: Configuration.builder(withAPIKey: Constants.revenueCat)
                .with(storeKitVersion: .storeKit2)
                .build()
        )
        
        for function in functionsToRegister {
            provider.registerFunction(
                name: function.name,
                description: function.description,
                parameters: function.parameters,
                handler: function.handler
            )
        }
        
        aiService = AIService(provider: self.provider)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(aiService)
                .environment(swiftDataDatasource)
                .tint(.appPrimary)
        }
        .modelContainer(modelContainer)
    }
}
