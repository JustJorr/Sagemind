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
      print("[REGISTER] Starting registration for email: $email, username: $username");
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      print("[REGISTER] Firebase Auth successful, uid: ${user?.uid}");
      
      if (user != null) {
        UserModel userModel = UserModel(
          id: user.uid,
          email: email,
          username: username,
          role: role,
        );
        
        print("[REGISTER] Creating Firestore user document...");
        await _firestore.createUser(userModel);
        print("[REGISTER] Firestore user created successfully");
        
        print("[REGISTER] Saving to SharedPreferences...");
        await _saveUserToPrefs(userModel);
        print("[REGISTER] Registration complete!");
        
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      print("[REGISTER ERROR] FirebaseAuthException: ${e.code} - ${e.message}");
    } catch (e) {
      print("[REGISTER ERROR] General error: $e");
    }
    return null;
  }

  // Login with email or username
  Future<UserModel?> login(String identifier, String password) async {
    try {
      print("[LOGIN] ========== LOGIN START ==========");
      print("[LOGIN] Identifier: $identifier");
      
      UserCredential result;
      String email = identifier;

      // Check if identifier is email or username
      if (!identifier.contains('@')) {
        print("[LOGIN] Identifier is not email, checking as username...");
        try {
          UserModel? userModel = await _firestore.getUserByUsername(identifier);
          if (userModel == null) {
            print("[LOGIN ERROR] Username not found: $identifier");
            return null;
          }
          email = userModel.email;
          print("[LOGIN] Username found, email: $email");
        } catch (e) {
          print("[LOGIN ERROR] Exception getting user by username: $e");
          return null;
        }
      } else {
        print("[LOGIN] Identifier is email");
      }

      // Login with email
      print("[LOGIN] Attempting Firebase Auth with email: $email");
      result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("[LOGIN] Firebase Auth successful!");

      User? user = result.user;
      print("[LOGIN] Firebase user uid: ${user?.uid}");
      
      if (user != null) {
        print("[LOGIN] Fetching user from Firestore with uid: ${user.uid}");
        try {
          UserModel? userModel = await _firestore.getUserById(user.uid);
          
          if (userModel != null) {
            print("[LOGIN] User found in Firestore!");
            print("[LOGIN] User: id=${userModel.id}, email=${userModel.email}, username=${userModel.username}, role=${userModel.role}");
            
            print("[LOGIN] Saving to SharedPreferences...");
            await _saveUserToPrefs(userModel);
            print("[LOGIN] ========== LOGIN SUCCESS ==========");
            return userModel;
          } else {
            print("[LOGIN ERROR] User document not found in Firestore!");
            print("[LOGIN ERROR] Checking if document exists at path: users/${user.uid}");
            return null;
          }
        } catch (e) {
          print("[LOGIN ERROR] Exception fetching from Firestore: $e");
          print("[LOGIN ERROR] Stack trace: ${e.toString()}");
          return null;
        }
      }
    } on FirebaseAuthException catch (e) {
      print("[LOGIN ERROR] FirebaseAuthException: ${e.code} - ${e.message}");
    } catch (e) {
      print("[LOGIN ERROR] General exception: $e");
      print("[LOGIN ERROR] Stack: ${e.toString()}");
    }
    print("[LOGIN] ========== LOGIN FAILED ==========");
    return null;
  }

  // Logout
  Future<void> logout() async {
    try {
      print("[LOGOUT] Signing out from Firebase...");
      await _auth.signOut();
      print("[LOGOUT] Clearing SharedPreferences...");
      await _clearUserFromPrefs();
      print("[LOGOUT] Logout complete!");
    } catch (e) {
      print("[LOGOUT ERROR] $e");
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
      print("[PREFS] Saved user to SharedPreferences");
    } catch (e) {
      print("[PREFS ERROR] Error saving user to prefs: $e");
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
        print("[PREFS] Retrieved user from prefs: id=$id");
        return UserModel(id: id, email: email, username: username, role: role);
      }
      print("[PREFS] No user data in SharedPreferences");
    } catch (e) {
      print("[PREFS ERROR] Error getting user from prefs: $e");
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
      print("[PREFS] Cleared user from SharedPreferences");
    } catch (e) {
      print("[PREFS ERROR] Error clearing user from prefs: $e");
    }
  }
}