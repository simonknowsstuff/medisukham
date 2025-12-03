import 'dart:io';
import 'dart:convert';
import 'package:medisukham/models/prescription_node.dart';
import 'package:flutter/foundation.dart'; // For kDebug
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PrescriptionAnalysisResult {
  final List<PrescriptionNode>? nodes;
  final String? errorMessage;

  PrescriptionAnalysisResult({this.nodes, this.errorMessage})
    : assert(nodes != null || errorMessage != null);

  bool get isSuccess => nodes != null;
}

// Sign-in anonymously to our firebase app
Future<User?> signInAnonymously() async {
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    return userCredential.user;
  } catch (e) {
    if (kDebugMode) {
      print('Anonymous sign-in failed');
    }
    return null;
  }
}

class GeminiApiService {
  // Ensures only one instance of the service exists globally.
  GeminiApiService._internal();
  static final GeminiApiService instance = GeminiApiService._internal();

  String _imageFileToBase64(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    return base64Encode(bytes);
  }

  Future<PrescriptionAnalysisResult> scanPrescription(
    File prescriptionImageFile,
  ) async {
    final base64Image = _imageFileToBase64(prescriptionImageFile);
    final functions = FirebaseFunctions.instance;
    final prompt =
        """
      You are a text extraction assistant.
      You will be given an image of a medical prescription.

      Your job:
      - Identify medicine names, dosages, and durations.
      - Prefer exact words or phrases found in the text.
      - If text is garbled (e.g., random numbers or unreadable words), ignore it.
      - Do NOT invent new medicine names or random numbers.
      - Each entry must be complete and meaningful.
      - Return a {} if there are absolutely no medicine names in the given image.

      Output format (valid JSON only):
      [
        { "medicine_name": "<name>", "dosages": "<dosage or frequency>" },
        ...
      ]
      Return each medicine’s dosages as: 
      { "start_date": "<YYYY-MM-DD>", "days": <number>, "timings": [{ "context": "<Morning|Afternoon|Evening|Night>" }] }
      Consider the start_date as ${DateFormat('yyyy-MM-dd').format(DateTime.now())}

      Now process this image:
    """;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await signInAnonymously();
    }

    final finalUser = FirebaseAuth.instance.currentUser;
    if (finalUser == null) {
      if (kDebugMode) {
        print('FATAL: Anonymous sign-in failed. Aborting function call.');
      }
      return PrescriptionAnalysisResult(
        errorMessage: 'Anonymous sign-in failed.',
      );
    }
    if (kDebugMode) {
      print('Successfully logged in!');
    }

    try {
      final HttpsCallable callable = functions.httpsCallable(
        'generateContentWithGemini',
      );
      final result = await callable.call(<String, dynamic>{
        'image': base64Image,
        'prompt': prompt,
      });
      final jsonString = result.data['result'] as String;
      if (kDebugMode) {
        print(jsonString);
      }

      final List<dynamic> rawList = jsonDecode(jsonString);

      final List<PrescriptionNode> nodes = rawList
          .where((jsonItem) => jsonItem != null)
          .map((jsonItem) {
            if (jsonItem is Map<String, dynamic>) {
              return PrescriptionNode.fromJson(jsonItem);
            }
            throw FormatException('Prescription node is not in proper format.');
          })
          .toList();

      return PrescriptionAnalysisResult(nodes: nodes);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('FATAL: Cloud Functions error: ${e.code} - ${e.message}');
      }
      return PrescriptionAnalysisResult(
        errorMessage: 'Cloud Functions error: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (e is FormatException) {
        if (kDebugMode) {
          print('FATAL: AI could not parse image into a valid list.');
        }
        return PrescriptionAnalysisResult(
          errorMessage: 'AI could not parse image into a valid list.',
        );
      }
      if (kDebugMode) {
        print('FATAL: Unexpected error occurred.');
        print(e);
      }
      return PrescriptionAnalysisResult(
        errorMessage: 'Unexpected error occurred.',
      );
    }
  }
}
