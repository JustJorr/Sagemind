# TODO for User Authentication and Role-Based Navigation

## 1. Update Dependencies
- [ ] Add firebase_auth and shared_preferences to pubspec.yaml
- [ ] Run flutter pub get

## 2. Create User Model
- [ ] Create lib/models/user_model.dart with fields: id, email, username, role

## 3. Update Firestore Services
- [ ] Add user-related methods to lib/services/firestore_services.dart: createUser, getUserById, getUserByEmail, getUserByUsername, updateUser, deleteUser

## 4. Create Auth Service
- [ ] Create lib/services/auth_service.dart for Firebase Auth: register, login (email or username), logout, current user, persistent login

## 5. Create Login and Register Screens
- [ ] Create lib/screen/login_screen.dart (login with email or username)
- [ ] Create lib/screen/register_screen.dart

## 6. Update App Navigation
- [ ] Update lib/app.dart to handle auth state and role-based navigation (admin dashboard or home screen)

## 7. Testing
- [ ] Test login/register functionality
- [ ] Test role-based navigation
- [ ] Test persistent login
