import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

/// Service to handle AI Skin Analysis.
class SkinAnalysisService {
  // TODO: Replace with your actual Gemini API Key from https://aistudio.google.com/app/apikey
  // The current key might be invalid or quota exceeded.
  static const String _apiKey = 'AIzaSyCWRBOXbkzcD-cLuAvXDzhxCPEDxeacdos';

  /// Analyzes the skin from the provided image file.
  Future<Map<String, dynamic>> analyzeSkin(XFile imageFile) async {
    // If no API key is set, fall back to simulation
    if (_apiKey.isEmpty) {
      return _simulateAnalysis();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final imageBytes = await imageFile.readAsBytes();
      final prompt = TextPart("""
      Analyze this image for skin health.
      
      If the image is completely black, not a face, or extremely low quality, return:
      {
        "error": "poor_quality"
      }

      Otherwise, analyze it and return a JSON object with NO markdown formatting.
      The JSON structure must be exactly:
      {
        "skinType": "String (e.g. Oily, Dry, Combination, Normal)",
        "metrics": {
          "texture": {"value": "String (e.g. Smooth, Uneven, Rough)", "status": "String (Good/Fair/Poor)"},
          "pores": {"value": "String (e.g. Tight, Visible, Enlarged)", "status": "String"},
          "pigmentation": {"value": "String (e.g. None, Mild, Spots)", "status": "String"},
          "acne": {"value": "String (e.g. None, Mild, Severe)", "status": "String"}
        },
        "summary": [
          "String (Detailed observation point 1)",
          "String (Detailed observation point 2)",
          "String (Detailed observation point 3)",
          "String (Detailed observation point 4)"
        ],
        "treatments": [
          {"name": "String (Choose from: Signature Facial, Lifting Facial, Collagen Facial, Whitening Facial, Acne Facial)", "reason": "String"}
        ]
      }
      
      For the 'treatments' array, select 2 most suitable treatments from this list based on the skin analysis:
      - Signature Facial (General maintenance)
      - Lifting Facial (For aging/sagging)
      - Collagen Facial (For wrinkles/firmness)
      - Whitening Facial (For pigmentation/dullness)
      - Acne Facial (For acne/breakouts)
      """);

      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [
        Content.multi([prompt, imagePart]),
      ];

      // Add a timeout to the API call to prevent hanging
      final response = await model
          .generateContent(content)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception("AI Request Timed Out"),
          );

      if (response.text == null) {
        throw Exception("Empty response from AI");
      }

      // Clean up markdown if present (Gemini sometimes adds ```json ... ```)
      String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleanJson);
    } catch (e, stackTrace) {
      debugPrint('AI Analysis failed: $e\n$stackTrace');

      rethrow;
    }
  }

  Future<Map<String, dynamic>> _simulateAnalysis() async {
    // We simulate a network delay to make it feel "real".
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    String skinType = [
      'Oily',
      'Dry',
      'Combination',
      'Normal',
    ][random.nextInt(4)];

    return {
      'skinType': skinType,
      'metrics': {
        'texture': {
          'value': ['Smooth', 'Uneven', 'Rough'][random.nextInt(3)],
          'status': ['Good', 'Fair', 'Poor'][random.nextInt(3)],
        },
        'pores': {
          'value': ['Tight', 'Visible', 'Enlarged'][random.nextInt(3)],
          'status': ['Good', 'Fair', 'Poor'][random.nextInt(3)],
        },
        'pigmentation': {
          'value': ['None', 'Mild', 'Spots'][random.nextInt(3)],
          'status': ['Good', 'Fair', 'Poor'][random.nextInt(3)],
        },
        'acne': {
          'value': ['None', 'Mild', 'Severe'][random.nextInt(3)],
          'status': ['Good', 'Fair', 'Poor'][random.nextInt(3)],
        },
      },
      'summary': [
        'Skin shows signs of dehydration in the T-zone.',
        'Texture is slightly uneven around the cheeks.',
        'Pores are visible but generally clear.',
        'Mild pigmentation detected on the forehead.',
      ],
      'treatments': [
        {
          "name": "Signature Facial",
          "reason": "To balance hydration and deep cleanse pores.",
        },
        {
          "name": "Whitening Facial",
          "reason": "To target mild pigmentation and brighten skin tone.",
        },
      ],
      'isSimulated': true,
    };
  }
}
