import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current logged-in Firebase user
  User? get currentUser => _auth.currentUser;

  // Auth state changes ko listen karne ke liye (login/logout track karta hai)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------- REGISTER ---------------------------------------------------------------------
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String role, // "admin" or "staff"
    required String phone,
  }) async {
    try {
      // Firebase Auth mein user create karna
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = credential.user!.uid;

      // UserModel banana
      UserModel newUser = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        phone: phone.trim(),
        createdAt: DateTime.now(),
      );

      // Firestore ke "users" collection mein save karna
      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  //-------------------- ADMIN CREATES STAFF ACCOUNT --------------------
  // Secondary Firebase app use karte hain taake Admin ka session logout na ho
  Future<void> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      UserCredential credential = await secondaryAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      String uid = credential.user!.uid;

      UserModel newStaff = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: 'staff',
        phone: phone.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(newStaff.toMap());

      // Secondary app se sign out aur delete, taake background mein na rahe
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    } on FirebaseAuthException catch (e) {
      await secondaryApp.delete();
      throw _handleAuthError(e);
    }
  }

  //-------------------- GET ALL STAFF MEMBERS --------------------
  Stream<List<UserModel>> getStaffList() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  //-------------------- UPDATE PROFILE IMAGE URL --------------------
  Future<void> updateProfileImage(String uid, String imageUrl) async {
    await _firestore.collection('users').doc(uid).update({
      'profileImageUrl': imageUrl.trim(),
    });
  }

  //-------------------- UPDATE STAFF INFO --------------------
  Future<void> updateStaffInfo({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
    });
  }

  //-------------------- TOGGLE STAFF ACTIVE STATUS --------------------
  Future<void> toggleStaffStatus(String uid, bool currentStatus) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': !currentStatus,
    });
  }

  //-------------------- DELETE STAFF ACCOUNT (Firestore record) --------------------
  // Note: Firebase Auth account delete karne ke liye Admin SDK/Cloud Function chahiye,
  // client-side se sirf apna khud ka account delete ho sakta hai.
  // Yahan hum Firestore se record hata dete hain, jisse staff app use nahi kar payega
  // kyunki login ke waqt Firestore mein uska data nahi milega.
  Future<void> deleteStaffAccount(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // ---------------- LOGIN -----------------------------------------------------------------
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = credential.user!.uid;

      // Firestore se user ka role aur baaki info fetch karna
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      if (!user.isActive && !user.isAdmin) {
        await _auth.signOut();
        throw 'Aapka account disabled/inactive hai. Admin se contact karein.';
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ---------------- LOGOUT -----------------------------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------- GET CURRENT USER DATA -----------------------------------------------------------------
  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    }
    return null;
  }

  // ---------------- GET USER DATA STREAM -----------------------------------------------------------------
  Stream<UserModel?> getUserStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    });
  }

  // ---------------- FORGOT PASSWORD --------------------------------------------------------------------------
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ---------------- CHANGE PASSWORD (IN-APP) -------------------------------------------------------------
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'No user is currently logged in.';
      }

      // Create a credential
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword.trim());
    } on FirebaseAuthException catch (e) {
      print("Firebase Password Change Error: ${e.code} - ${e.message}");
      throw _handleAuthError(e);
    } catch (e) {
      print("General Password Change Error: $e");
      rethrow;
    }
  }

  //-------------------- ERROR HANDLING --------------------
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'This email is not registered.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Something went wrong: ${e.message}';
    }
  }
}

/*


register() → Pehle Firebase Auth mein account banata hai (email/password se), phir Firestore ke users collection mein user ki extra info (naam, role, phone) save karta hai
login() → Email/password check karta hai, phir Firestore se user ka role fetch karta hai (taake pata chale Admin hai ya Staff)
logout() → Session khatam karta hai
resetPassword() → Forgot password ke liye reset email bhejta hai
_handleAuthError() → Firebase ke technical error messages ko simple Roman Urdu/Urdu-friendly messages mein convert karta hai


 */
