import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  var current_image_url=null;
  final saved = <String>{};
  Status _status = Status.Uninitialized;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseStorage _fireStorage = FirebaseStorage.instance;
  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Status get status => _status;

//  Set get saved => _saved;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      try {
        current_image_url =
        await _fireStorage.ref('images').child(user!.email!).getDownloadURL();
      }catch(e){
        current_image_url=null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> addPair(String pair) async {
    saved.add(pair);
    notifyListeners();
    updateDB();
  }

  Future<void> removePair(String pair) async {
    saved.remove(pair);
    notifyListeners();
    updateDB();
  }

  Future<void> updateDB() async {
   if (user != null) {
      await _firestore.collection('users').doc(user!.email).set({
        "wordPairs": saved.toList(),
      });
    }
  }

    Future<void> updatePairsAfterLoggingIn()async {
      if (user != null) {
        await _firestore.collection('users').doc(user!.email).get().then((snapshot) {
          if (snapshot.exists) {
            saved.addAll(snapshot.data()!['wordPairs'].cast<String>());
          }
          updateDB();
          notifyListeners();
        });
      }
    }


  Future<void> signOut() async {
    _auth.signOut();
    saved.clear();
    current_image_url=null;
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }
  Future<void> update_image_url(String? key,String image)async{
    current_image_url=await _fireStorage.ref('images').child(key!).putFile(File(image)).then((file) => file.ref.getDownloadURL());
    notifyListeners();
  }
}