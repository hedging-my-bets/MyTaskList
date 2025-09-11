# Overview

This is a React Native Expo application built as a prototype for a pet evolution to-do app. The app features time-slotted task management with a virtual pet that evolves based on task completion rates. Users can create, complete, and snooze tasks while watching their pet progress through 20 different evolutionary stages. The application is designed to be ported to native iOS with WidgetKit Lock Screen widget support.

# User Preferences

Preferred communication style: Simple, everyday language.

# System Architecture

## Frontend Architecture
- **Framework**: React Native with Expo SDK ~53.0.9
- **Routing**: File-based routing using expo-router with typed routes
- **UI Components**: Custom themed components built on React Native primitives
- **Navigation**: Tab-based navigation with React Navigation bottom tabs
- **State Management**: Local component state with React hooks, no global state manager
- **Styling**: StyleSheet API with theme-aware components supporting light/dark modes

## Data Layer
- **Storage**: AsyncStorage for local data persistence
- **Data Models**: TypeScript interfaces for TaskItem, PetState, AppSettings, and StageForm
- **Services**: Service layer pattern with TaskService and DailyCloseoutService for business logic
- **Engine**: Pure function-based PetEngine for evolution/de-evolution calculations

## Core Business Logic
- **Task Management**: Time-slotted to-do items with scheduling, completion, and snooze functionality
- **Pet Evolution**: 20-stage progression system driven by task completion rates
- **Daily Closeout**: Automated daily processing for pet evolution based on completion statistics
- **Progress Tracking**: Stage-based XP system with configurable thresholds

## Component Architecture
- **Themed Components**: ThemedText and ThemedView for consistent styling across light/dark modes
- **Reusable UI**: Modular components for pet display, progress bars, task items, and time pickers
- **Cross-Platform Compatibility**: Platform-specific implementations for iOS symbols and Android Material Icons

## Data Flow
- Tasks are stored locally with day-based partitioning (YYYY-MM-DD format)
- Pet state persists across app sessions with XP tracking and stage progression
- Daily closeout runs automatically on app launch when reset time threshold is passed
- All data operations go through service layer for consistency and error handling

# External Dependencies

## Core Dependencies
- **Expo SDK**: Complete development platform with managed workflow
- **React Navigation**: Tab navigation and routing infrastructure
- **AsyncStorage**: Local data persistence for tasks and pet state
- **React Native Reanimated**: Animation library for smooth UI transitions
- **React Native Gesture Handler**: Touch gesture recognition

## UI and UX Libraries
- **Expo Vector Icons**: Icon library with Material Icons and SF Symbols support
- **Expo Blur**: Native blur effects for iOS tab bar background
- **Expo Haptics**: Tactile feedback for user interactions
- **Expo Font**: Custom font loading and management

## Platform Integration
- **Expo Router**: File-based routing with deep linking support
- **Expo Status Bar**: Status bar styling and configuration
- **Expo System UI**: System UI customization and theming
- **React Native Safe Area Context**: Safe area handling for notched devices

## Development Tools
- **TypeScript**: Type safety and development experience
- **ESLint**: Code quality and consistency enforcement with Expo configuration
- **Jest**: Testing framework with Expo preset
- **Babel**: JavaScript compilation with Expo configuration

## Future iOS Integration
The app is structured for porting to native iOS with WidgetKit support. The TypeScript data models, business logic, and UI patterns are designed to translate directly to SwiftUI and SwiftData implementations. The PetEngine and service layer architecture matches the intended native iOS structure documented in the included porting guides.