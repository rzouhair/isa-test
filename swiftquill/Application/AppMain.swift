import Foundation
import SwiftUI
import Firebase
import RevenueCat
import SwiftData

@main
struct AppMain: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    @State private var appState = AppState()
    
    private var provider = OpenAIProvider(apiKey: Constants.openAIKey)
    @State private var aiService: AIService

    var sharedModelContainer: ModelContainer = {
      let schema = Schema([
          Item.self,
      ])
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

      do {
          return try ModelContainer(for: schema, configurations: [modelConfiguration])
      } catch {
          fatalError("Could not create ModelContainer: \(error)")
      }
    }()
    
    init() {
        FirebaseApp.configure()
        Purchases.configure(withAPIKey: Constants.revenueCat)
        
        self.provider.registerFunction(
            name: WeatherFunction.name,
            description: WeatherFunction.description,
            parameters: WeatherFunction.parameters,
            handler: WeatherFunction.handler
        )
        aiService = AIService(provider: self.provider)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(aiService)
        }
        .modelContainer(sharedModelContainer)
    }
} 
