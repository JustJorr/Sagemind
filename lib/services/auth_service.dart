import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_services.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreServices _firestore = FirestoreServices();

  // Register with email and password
  Future<UserModel?> register(String email, String password, String username, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        UserModel userModel = UserModel(
          id: user.uid,
          email: email,
          username: username,
          role: role,
        );
        await _firestore.createUser(userModel);
        await _saveUserToPrefs(userModel);
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      print("Register error: ${e.code} - ${e.message}");
    } catch (e) {
      print("Register error: $e");
    }
    return null;
  }

  // Login with email or username
  Future<UserModel?> login(String identifier, String password) async {
    try {
      UserCredential result;
      String email = identifier;

      // Check if identifier is email or username
      if (!identifier.contains('@')) {
        // Login with username - first get user by username
        UserModel? userModel = await _firestore.getUserByUsername(identifier);
        if (userModel == null) {
          print("User not found with username: $identifier");
          return null;
        }
        email = userModel.email;
      }

      // Login with email
      result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        UserModel? userModel = await _firestore.getUserById(user.uid);
        if (userModel != null) {
          await _saveUserToPrefs(userModel);
          return userModel;
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Login error: ${e.code} - ${e.message}");
    } catch (e) {
      print("Login error: $e");
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _clearUserFromPrefs();
    } catch (e) {
      print("Logout error: $e");
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _firestore.getUserById(user.uid);
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    User? user = _auth.currentUser;
    return user != null;
  }

  // Save user to shared preferences
  Future<void> _saveUserToPrefs(UserModel user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_username', user.username);
      await prefs.setString('user_role', user.role);
    } catch (e) {
      print("Error saving user to prefs: $e");
    }
  }

  // Get user from shared preferences
  Future<UserModel?> getUserFromPrefs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('user_id');
      String? email = prefs.getString('user_email');
      String? username = prefs.getString('user_username');
      String? role = prefs.getString('user_role');
      if (id != null && email != null && username != null && role != null) {
        return UserModel(id: id, email: email, username: username, role: role);
      }
    } catch (e) {
      print("Error getting user from prefs: $e");
    }
    return null;
  }

  // Clear user from shared preferences
  Future<void> _clearUserFromPrefs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_username');
      await prefs.remove('user_role');
    } catch (e) {
      print("Error clearing user from prefs: $e");
    }
  }
}