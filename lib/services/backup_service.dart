import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

//-------------------- BACKUP & RESTORE SERVICE --------------------
// Export: saari Firestore collections ko ek JSON file mein save karta hai.
// Import: JSON file se data wapas Firestore mein upload karta hai.
class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //-------------------- COLLECTIONS INCLUDED IN BACKUP --------------------
  static const List<String> collections = [
    'users',
    'products',
    'customers',
    'invoices',
    'suppliers',
    'purchase_orders',
    'payroll',
    'expenses',
    'customer_payments',
    'attendance',
    'leave_requests',
    'urgent_alerts',
  ];

  //-------------------- EXPORT BACKUP (Firestore -> JSON File) --------------------
  // User ko save location choose karne deta hai.
  // Returns saved file path, ya null agar user ne cancel kar diya.
  Future<Map<String, dynamic>?> exportBackup() async {
    final Map<String, dynamic> backupData = {
      'backupVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
    };

    int totalRecords = 0;
    final Map<String, int> countsPerCollection = {};

    //---------- STEP 1: SAARI COLLECTIONS PADHNA ----------
    for (final collectionName in collections) {
      final snapshot = await _firestore.collection(collectionName).get();

      final docs = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['_id'] = doc.id; // document id restore ke liye zaroori hai
        return _encodeValue(data) as Map<String, dynamic>;
      }).toList();

      backupData[collectionName] = docs;
      countsPerCollection[collectionName] = docs.length;
      totalRecords += docs.length;
    }

    backupData['totalRecords'] = totalRecords;

    //---------- STEP 2: JSON STRING BANANA ----------
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    //---------- STEP 3: FILE NAME BANANA ----------
    final now = DateTime.now();
    final fileName =
        'ERP_Backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.json';

    //---------- STEP 4: USER SE SAVE LOCATION POOCHNA ----------
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Select location to save backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (savePath == null) return null; // user ne cancel kar diya

    //---------- STEP 5: FILE WRITE KARNA ----------
    final finalPath = savePath.toLowerCase().endsWith('.json')
        ? savePath
        : '$savePath.json';
    final file = File(finalPath);
    await file.writeAsString(jsonString);

    return {
      'path': file.path,
      'totalRecords': totalRecords,
      'counts': countsPerCollection,
    };
  }

  //-------------------- PICK BACKUP FILE (for Restore) --------------------
  Future<File?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose JSON backup file',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return null;
    return File(result.files.single.path!);
  }

  //-------------------- VALIDATE BACKUP FILE --------------------
  // Valid hone par parsed data return karta hai, warna Exception throw karta hai.
  Future<Map<String, dynamic>> validateBackupFile(File file) async {
    final String content;
    try {
      content = await file.readAsString();
    } catch (_) {
      throw 'Could not read this file.';
    }

    late Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw 'This file is not valid JSON.';
    }

    final hasAnyCollection = collections.any((c) => data.containsKey(c));
    if (!hasAnyCollection) {
      throw 'This does not look like a valid ERP backup file.';
    }

    return data;
  }

  //-------------------- RESTORE BACKUP (JSON -> Firestore) --------------------
  // Har collection ka record count return karta hai.
  Future<Map<String, int>> restoreBackup(Map<String, dynamic> data) async {
    final Map<String, int> results = {};

    for (final collectionName in collections) {
      final rawList = data[collectionName];
      if (rawList == null || rawList is! List) {
        results[collectionName] = 0;
        continue;
      }

      final docs = rawList.cast<Map<String, dynamic>>();
      int count = 0;

      //---------- FIRESTORE BATCH LIMIT: 500 WRITES PER BATCH ----------
      for (var i = 0; i < docs.length; i += 450) {
        final batch = _firestore.batch();
        final chunk = docs.skip(i).take(450);

        for (final rawDoc in chunk) {
          final docMap = Map<String, dynamic>.from(_decodeValue(rawDoc) as Map);
          final id = docMap.remove('_id') as String?;

          final ref = id != null
              ? _firestore.collection(collectionName).doc(id)
              : _firestore.collection(collectionName).doc();

          batch.set(ref, docMap);
          count++;
        }

        await batch.commit();
      }

      results[collectionName] = count;
    }

    return results;
  }

  //-------------------- RESET SYSTEM (DELETE ALL DATA) --------------------
  // Products, Customers, Invoices poori tarah delete hoti hain.
  // Users collection se sirf baaki sab delete hote hain — jo Admin abhi
  // login hai uska account SAFE rehta hai, taake wo lock out na ho.
  // Returns har collection ka deleted count.
  Future<Map<String, int>> resetSystem() async {
    final Map<String, int> deletedCounts = {};
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    //---------- FULLY WIPE: all transactional and business collections ----------
    final collectionsToWipe = [
      'products',
      'customers',
      'invoices',
      'suppliers',
      'purchase_orders',
      'payroll',
      'expenses',
      'customer_payments',
      'attendance',
    ];
    for (final collectionName in collectionsToWipe) {
      final snapshot = await _firestore.collection(collectionName).get();
      int count = 0;

      for (var i = 0; i < snapshot.docs.length; i += 450) {
        final batch = _firestore.batch();
        final chunk = snapshot.docs.skip(i).take(450);
        for (final doc in chunk) {
          batch.delete(doc.reference);
          count++;
        }
        await batch.commit();
      }
      deletedCounts[collectionName] = count;
    }

    //---------- USERS: DELETE ALL EXCEPT CURRENT ADMIN ----------
    final usersSnapshot = await _firestore.collection('users').get();
    int deletedUsers = 0;

    for (var i = 0; i < usersSnapshot.docs.length; i += 450) {
      final batch = _firestore.batch();
      final chunk = usersSnapshot.docs.skip(i).take(450);
      for (final doc in chunk) {
        if (doc.id == currentUid) continue; // apna account safe rakho
        batch.delete(doc.reference);
        deletedUsers++;
      }
      await batch.commit();
    }
    deletedCounts['users (staff removed)'] = deletedUsers;

    return deletedCounts;
  }

  //-------------------- TIMESTAMPS/DATES RECURSIVE SERIALIZATION HELPERS --------------------
  dynamic _encodeValue(dynamic value) {
    if (value is Timestamp) {
      return {
        '_type': 'Timestamp',
        'seconds': value.seconds,
        'nanoseconds': value.nanoseconds,
      };
    } else if (value is DateTime) {
      final ts = Timestamp.fromDate(value);
      return {
        '_type': 'Timestamp',
        'seconds': ts.seconds,
        'nanoseconds': ts.nanoseconds,
      };
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _encodeValue(v)));
    } else if (value is List) {
      return value.map((v) => _encodeValue(v)).toList();
    }
    return value;
  }

  dynamic _decodeValue(dynamic value) {
    if (value is Map) {
      if (value['_type'] == 'Timestamp') {
        final seconds = value['seconds'] as int;
        final nanoseconds = value['nanoseconds'] as int;
        return Timestamp(seconds, nanoseconds);
      }
      return value.map((k, v) => MapEntry(k.toString(), _decodeValue(v)));
    } else if (value is List) {
      return value.map((v) => _decodeValue(v)).toList();
    }
    return value;
  }
}
