# 📚 Sline Project - Complete Reference Guide

*Last Updated: 2025-07-25*

## 🎯 Project Overview

**Sline** is a Flutter-based freelance marketplace application that connects clients with freelancers. The app enables users to post jobs, find freelancers, communicate, and manage projects through a modern mobile interface.

### Core Concept
- **Clients**: Post jobs, browse freelancer profiles, hire talent
- **Freelancers**: Browse jobs, submit proposals, showcase skills
- **Platform**: Facilitates secure communication, payments, and project management

## 🏗️ Technical Architecture

### Framework & Technologies
- **Frontend**: Flutter (Material Design 3)
- **Backend**: Supabase (BaaS - Backend as a Service)
- **State Management**: Provider with ChangeNotifier pattern
- **Authentication**: Supabase Auth (email/password)
- **Database**: PostgreSQL (via Supabase)
- **Storage**: Supabase Storage (for avatars, files)
- **Image Handling**: image_picker package

### Architecture Principles
- **Modular Structure**: Feature-based organization (`lib/features/`)
- **Separation of Concerns**: Controllers, repositories, UI separated
- **No Global State**: Each feature has its own ChangeNotifier
- **Repository Pattern**: Backend calls abstracted through repositories

## 📁 Project Structure

```
sline_app/
├── lib/
│   ├── core/
│   │   ├── models/          # Shared data models
│   │   ├── repositories/    # Data access layer
│   │   └── services/        # Core services (Supabase config)
│   ├── features/
│   │   ├── auth/           # Authentication feature
│   │   │   ├── controller/ # AuthController
│   │   │   ├── data/       # AuthRepository
│   │   │   ├── model/      # Auth models
│   │   │   └── ui/         # Login/Signup screens
│   │   ├── profile/        # User profile management
│   │   │   └── ui/
│   │   │       ├── controller/    # ProfileController
│   │   │       ├── widgets/       # Profile UI components
│   │   │       └── profile_screen.dart
│   │   ├── home/           # Main dashboard
│   │   ├── tasks/          # Job listings (planned)
│   │   ├── chat/           # Messaging (planned)
│   │   └── booking/        # Project management (planned)
│   └── main.dart           # App entry point
├── assets/
│   └── images/             # App logo and images
├── integration_test/       # Integration tests
├── test/                   # Unit tests
└── Documentation files:
    ├── README.md
    ├── PROJECT_LOG.md
    ├── SUPABASE_SETUP.md
    └── README_SLINE_OVERVIEW.md
```

## 🗄️ Database Schema (Supabase)

### Current Tables

#### `users` Table
```sql
- id (UUID, primary key)
- full_name (text)
- email (text)
- avatar_url (text)
- phone (text, optional)
- created_at (timestamp)
```

#### `roles` Table
```sql
- id (UUID, primary key)
- name (text): "client" | "freelancer"
```

#### `user_roles` Table (M2M)
```sql
- user_id (UUID, foreign key to users)
- role_id (UUID, foreign key to roles)
```

### Security Policies (RLS)
- **users**: Select, insert, update allowed if authenticated user ID matches row's ID
- **roles**, **user_roles**: Read-only access for all authenticated users

### Planned Tables
- `tasks`: Job listings with user_id (posted_by), status, description, budget
- `proposals`: Freelancer applications to jobs
- `messages`: Chat system between users
- `projects`: Active work agreements

## 💻 Key Implementation Details

### Main App Entry Point (`main.dart`)
```dart
// Provider setup with ProfileController
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProfileController()),
  ],
  child: MaterialApp(
    // Route to HomeScreen if authenticated, LoginScreen if not
    home: Supabase.instance.client.auth.currentUser != null
        ? const HomeScreen()
        : const LoginScreen(),
  ),
)
```

### Authentication Flow (`AuthController`)
- **Login**: Email/password validation → Supabase auth → Navigate to HomeScreen
- **Register**: Email/password/fullName → Create user → Auto-login → HomeScreen
- **Error Handling**: Proper async context checks with `mounted` validation
- **Repository Pattern**: Uses `AuthRepository` for all Supabase calls

### Profile Management (`ProfileController`)
- **State Management**: Extends ChangeNotifier for reactive UI updates
- **Form Controllers**: TextEditingController for name, email, bio fields
- **Image Upload**: XFile handling with Supabase Storage integration
- **Role Switching**: Toggle between client/freelancer roles
- **Data Sync**: Bidirectional sync with Supabase profiles table

### UI/UX Principles
- **Material Design 3**: Consistent design language
- **Form Validation**: TextFormField with proper validation
- **Loading States**: Loading indicators during async operations
- **Error Feedback**: SnackBar messages for user feedback
- **Responsive Design**: Proper widget hierarchy and constraints

## 🚀 Development Status

### ✅ Completed Features
1. **Authentication System**
   - Email/password signup and login
   - User session management
   - Logout functionality
   - Proper error handling and navigation

2. **Profile Management**
   - Complete user profile editing
   - Avatar upload with image picker
   - Role switching (client ↔ freelancer)
   - Real-time data sync with backend

3. **Core Infrastructure**
   - Supabase integration and configuration
   - Provider state management setup
   - Modular project structure
   - Database schema with RLS policies

### 🔄 Current State
- **Functional**: Users can register, login, and manage profiles
- **Navigation**: Basic routing between auth and home screens
- **Home Screen**: Exists but minimal (placeholder)
- **Architecture**: Ready for feature expansion

### 📋 Next Development Priorities

#### 1. Tasks/Job Listings System (High Priority)
```dart
// Planned implementation:
- TasksController extends ChangeNotifier
- TaskRepository for Supabase integration
- Job posting UI for clients
- Job browsing UI for freelancers
- Task status management (open, in-progress, completed)
```

#### 2. Chat/Messaging System (Medium Priority)
```dart
// Planned features:
- Real-time messaging with Supabase Realtime
- ChatController for message management
- Conversation threads between users
- Message history and notifications
```

#### 3. Booking/Project Management (Medium Priority)
```dart
// Planned features:
- Project workflow management
- Milestone tracking
- Payment integration
- File sharing capabilities
```

## 🔧 Development Guidelines

### Code Style
- **Language**: English for all code and comments
- **Variables**: Use `late final` or `final` over mutable variables
- **Async**: Always check `mounted` after async calls in StatefulWidget
- **Comments**: Inline comments for complex logic
- **Naming**: Descriptive names following Dart conventions

### State Management Rules
- **No Global State**: Each feature manages its own state
- **Provider Pattern**: Use ChangeNotifier for feature-specific state
- **Local State**: Handle form inputs within StatefulWidget when appropriate
- **Repository Pattern**: Never call Supabase directly from UI

### Testing Strategy
- **Unit Tests**: `test/` directory for business logic
- **Integration Tests**: `integration_test/` for full user flows
- **Widget Tests**: Test UI components in isolation

### Common Issues & Solutions

#### 1. ProviderNotFoundException
```dart
// Solution: Ensure Provider is above widget in tree
MultiProvider(
  providers: [ChangeNotifierProvider(create: (_) => YourController())],
  child: YourWidget(),
)
```

#### 2. Supabase Query Errors
```dart
// Solution: Always handle exceptions and check user auth
try {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) throw Exception('User not authenticated');
  // Your query here
} catch (e) {
  // Handle error appropriately
}
```

#### 3. Context Usage After Async
```dart
// Solution: Always check mounted before using context
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(/* ... */);
```

## 🎨 UI/UX Standards

### Design System
- **Primary Colors**: Blue theme with Material Design 3
- **Typography**: Roboto font family
- **Components**: Prefer Material widgets (TextFormField, ElevatedButton, ListView)
- **Spacing**: Consistent padding and margins
- **Feedback**: Loading states and error messages

### User Experience
- **Navigation**: Clear flow between screens
- **Validation**: Real-time form validation
- **Accessibility**: Proper semantic labels
- **Performance**: Efficient widget rebuilds with Provider

## 📝 Development Notes

### Supabase Integration
- **Configuration**: Initialized in `core/services/supabase_config.dart`
- **Auth State**: Checked in main.dart for routing decisions
- **Storage**: Used for avatar uploads with public URLs
- **RLS**: All tables secured with row-level security

### Image Handling
- **Package**: image_picker for camera/gallery access
- **Storage**: Supabase Storage bucket 'avatars'
- **Format**: Maintains original file extension
- **Upsert**: Overwrites existing avatars

### Error Handling Patterns
```dart
// Standard error handling pattern
try {
  // Supabase operation
  await repository.someOperation();
  if (!state.mounted) return;
  // Success feedback
} catch (e) {
  if (!state.mounted) return;
  // Error feedback
}
```

## 🔮 Future Considerations

### Scalability
- **Caching**: Implement local caching for frequently accessed data
- **Pagination**: Add pagination for job listings and chat history
- **Offline Support**: Consider offline capabilities for core features

### Features to Consider
- **Push Notifications**: For new messages and job updates
- **Search & Filters**: Advanced job search capabilities
- **Reviews & Ratings**: User feedback system
- **Payment Integration**: Stripe or similar payment processor
- **File Sharing**: Document exchange between users

### Performance Optimizations
- **Image Optimization**: Compress uploaded images
- **Lazy Loading**: Implement for large lists
- **State Optimization**: Minimize unnecessary rebuilds

---

*This reference document should be updated as the project evolves. Key changes to track: new features, architectural decisions, database schema updates, and major bug fixes.*