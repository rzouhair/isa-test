# PaperScan - AI Context Guide

> OpenCode instructions file. See also: CLAUDE.md (canonical source, with full folder descriptions).

## Project Overview

PaperScan is an iOS app built with **SwiftUI** and **Swift 6**, following **MVVM + Clean Architecture**. Subscriptions via **RevenueCat**.

## Architecture

- **Application/** — App lifecycle and bootstrap. `AppMain.swift` is the `@main` entry point that wires up SwiftData, RevenueCat, AI services, and SwiftUI environment injection. `AppState` holds global state. `RootView` decides what to show (onboarding vs main app).

- **Core/DI/** — Dependency injection container. Register new service bindings here when adding protocol/implementation pairs.
- **Core/Navigation/** — `Router.swift` with a typed `Route` enum. Add new cases here for new screens. Uses `NavigationStack`.

- **Data/Datasources/** — Low-level data access (SwiftData, UserDefaults). New persistence backends go here.
- **Data/Repositories/** — Mediates between datasources and app logic. Conforms to protocols in `Domain/Protocols`. Call repositories, not datasources directly.
- **Data/Services/** — External API integrations (network calls). One service per external dependency.

- **Domain/Models/** — Shared data structures. SwiftData `@Model` classes live here. No UI or networking logic.
- **Domain/Protocols/** — Interfaces that decouple layers. Define protocols here before implementing.
- **Domain/Enums/** — Shared enumerations across features.
- **Domain/Functions/** — AI function-calling definitions (tool use). Register new functions in `AppMain.swift`.
- **Domain/Prompts/** — AI prompt templates. Keep prompt text here, not inline in ViewModels.
- **Domain/Utilities/** — Parsers and helpers with no UI dependency.

- **Features/** — Self-contained feature modules (View + ViewModel each). Features should not import each other — communicate through Router or shared Domain models.
  - `Home/` — Main dashboard / landing screen.
  - `CameraCapture/` — Camera, photo picker, crop frame.
  - `Settings/` — App settings, mail composer, about page.
  - `Purchases/` — Paywall and subscription management (Data/, Utils/, Views/).
  - `OnboardingFlow/` — Multi-step onboarding with permission requests.

- **Presentation/Components/** — Reusable, feature-agnostic UI blocks. If used in 2+ features, it belongs here.
- **Presentation/Extensions/** — Swift/SwiftUI type extensions. Keep small and single-type focused.
- **Presentation/Resources/** — Asset catalogs (Colors, Images, Fonts). Run SwiftGen after changes.
- **Presentation/Generated/** — SwiftGen output. Do NOT edit manually.

- **Constants.swift** — API keys, URLs, app metadata, product IDs. Update when changing environments or branding.

## Code Conventions

- **Swift 6** with strict concurrency
- **@Observable** macro for ViewModels (not ObservableObject)
- **async/await** for all async work
- **Value types** preferred, except SwiftData @Model classes
- Protocol-oriented design; camelCase vars, PascalCase types
- Boolean: `is`/`has`/`should` prefix; methods: verb-first naming

## Key Dependencies

RevenueCat, SwiftData, AVFoundation, SwiftGen, Inject, Mixpanel

## Guidelines

- Apple HIG compliance, dark mode, dynamic type, SF Symbols
- Each feature module: self-contained View + ViewModel
- Inject dependencies via protocols for testability
- Lazy load views/images for performance
