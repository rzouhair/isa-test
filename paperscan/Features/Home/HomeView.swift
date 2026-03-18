import SwiftUI
import Inject

struct HomeView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router: Router
    @Environment(AppState.self) private var appState: AppState
    @State private var viewModel: HomeViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Scan CTA Button
                Button {
                    viewModel?.openCamera()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Start Scanning")
                            .font(.title3.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.appPrimary.gradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                VStack {
                    Spacer()

                    ContentUnavailableView {
                        Label("Ready to scan", systemImage: "camera.viewfinder")
                    } description: {
                        Text("Tap the button above or use the camera to get started")
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(router: router, appState: appState)
            }
        }
        .enableInjection()
    }
}

#Preview {
    let router = Router()
    let appState = AppState()

    return NavigationStack {
        HomeView()
            .environment(router)
            .environment(appState)
    }
}
