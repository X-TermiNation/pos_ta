import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/tools/custom_toast.dart';

Future<Map<String, dynamic>?> insertQuestion(String questionText) async {
  final url = Uri.parse("http://localhost:3000/chatbot/question");
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_cabang": id_cabang,
        "questionText": questionText,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("Error: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Error inserting question: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> insertAnswer(
    String questionId, String answerText, String? action) async {
  final url = Uri.parse("http://localhost:3000/chatbot/answer");
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_cabang": id_cabang,
        "questionId": questionId,
        "answerText": answerText,
        "action": action,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("Error: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Error inserting answer: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> getFirstQuestion() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url =
      Uri.parse("http://localhost:3000/chatbot/question/first/$id_cabang");
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Error: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Error fetching first question: $e");
    return null;
  }
}

Future<bool> updateNextQuestion(
    String questionId, String answerId, String newNextQuestionID) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url =
      Uri.parse("http://localhost:3000/chatbot/answer/update-next-question");

  try {
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_cabang": id_cabang,
        "questionId": questionId,
        "answerId": answerId,
        "newNextQuestionID": newNextQuestionID,
      }),
    );

    return response.statusCode == 200;
  } catch (e) {
    print("Error updating next question: $e");
    return false;
  }
}

// Update the first question ID
Future<bool> updateFirstQuestionID(String newFirstQuestionID) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url =
      Uri.parse("http://localhost:3000/chatbot/updateFirstQuestion/$id_cabang");

  try {
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "newFirstQuestionID": newFirstQuestionID,
      }),
    );

    return response.statusCode == 200;
  } catch (e) {
    print("Error updating first question ID: $e");
    return false;
  }
}

// Delete a question
Future<bool> deleteQuestion(String questionID) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url = Uri.parse(
      "http://localhost:3000/chatbot/deleteQuestion/$id_cabang/$questionID");

  try {
    final response = await http.delete(url);

    return response.statusCode == 200;
  } catch (e) {
    print("Error deleting question: $e");
    return false;
  }
}

// Delete an answer
Future<bool> deleteAnswer(String questionID, String answerID) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url = Uri.parse(
      "http://localhost:3000/chatbot/deleteAnswer/$id_cabang/$questionID/$answerID");

  try {
    final response = await http.delete(url);

    return response.statusCode == 200;
  } catch (e) {
    print("Error deleting answer: $e");
    return false;
  }
}

// Get all questions for a cabang
Future<List<dynamic>> getAllQuestions() async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url =
      Uri.parse("http://localhost:3000/chatbot/getAllQuestions/$id_cabang");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);

      if (decodedResponse is Map<String, dynamic> &&
          decodedResponse.containsKey('questions')) {
        return decodedResponse['questions'] as List<dynamic>;
      } else {
        print("Unexpected response format: $decodedResponse");
        return [];
      }
    } else {
      print("Failed to get questions: ${response.body}");
      return [];
    }
  } catch (e) {
    print("Error getting questions: $e");
    return [];
  }
}

// Get all answers for a specific question
Future<List<dynamic>> getAllAnswers(String questionID) async {
  final dataStorage = GetStorage();
  String id_cabang = dataStorage.read('id_cabang');
  final url = Uri.parse(
      "http://localhost:3000/chatbot/getAllAnswers/$id_cabang/$questionID");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to get answers: ${response.body}");
      return [];
    }
  } catch (e) {
    print("Error getting answers: $e");
    return [];
  }
}
