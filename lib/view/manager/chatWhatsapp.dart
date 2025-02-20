import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:ta_pos/view/view-model-flutter/chatbot_controller.dart';

class ChatbotManagerScreen extends StatefulWidget {
  @override
  _ChatbotManagerScreenState createState() => _ChatbotManagerScreenState();
}

class _ChatbotManagerScreenState extends State<ChatbotManagerScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final Uuid uuid = Uuid();

  List<Map<String, dynamic>> questions = [];
  String? selectedQuestionId;
  String? firstQuestionId; // Variable to hold the first question ID

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    var chatbotData = await getAllQuestions();

    if (chatbotData != null && chatbotData['success'] == true) {
      setState(() {
        questions =
            List<Map<String, dynamic>>.from(chatbotData['questions'] ?? []);

        // Assign firstQuestionID directly from API response
        firstQuestionId = chatbotData['firstQuestionID'];
      });
    }
  }

  Future<void> addQuestion() async {
    String questionText = _questionController.text.trim();
    if (questionText.isNotEmpty) {
      var response = await insertQuestion(questionText);
      if (response != null &&
          response is Map<String, dynamic> &&
          response['success'] == true) {
        _questionController.clear();
        fetchQuestions(); // Refresh list
      }
    }
  }

  Future<void> addAnswer() async {
    if (selectedQuestionId == null) return;
    String answerText = _answerController.text.trim();
    if (answerText.isNotEmpty) {
      await insertAnswer(selectedQuestionId!, answerText, null);
      _answerController.clear();
      fetchQuestions(); // Refresh list
    }
  }

  Future<void> deleteQuestionFunc(String questionId) async {
    await deleteQuestion(questionId);
    setState(() {
      selectedQuestionId = null;
    });
    fetchQuestions(); // Refresh list
  }

  Future<void> deleteAnswerFunc(String questionId, String answerId) async {
    bool success = await deleteAnswer(questionId, answerId);
    if (success) {
      await fetchQuestions();
      setState(() {});
    } else {
      print("Failed to delete answer.");
    }
  }

  Future<void> updateNextQuestionForAnswer(
      String selectedQuestionId, String answerId, String newQuestionId) async {
    if (selectedQuestionId.isEmpty) return; // Prevent empty ID
    bool success =
        await updateNextQuestion(selectedQuestionId, answerId, newQuestionId);
    if (success) fetchQuestions(); // Refresh UI
  }

  // Function to update the first question ID in the database
  Future<void> setFirstQuestion(String questionId) async {
    if (firstQuestionId == questionId) return; // Prevent unnecessary updates

    bool success =
        await updateFirstQuestionID(questionId); // Call API to update
    if (success) {
      setState(() {
        firstQuestionId = questionId; // Update UI immediately
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatbot Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Question:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter question',
                suffixIcon: IconButton(
                    icon: const Icon(Icons.add), onPressed: addQuestion),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Questions List:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  var q = questions[index];
                  bool isFirstQuestion = firstQuestionId == q['_id'];

                  return ListTile(
                    title: Text('${index + 1}. ${q['questionText']}'),
                    tileColor: selectedQuestionId == q['_id']
                        ? Colors.grey[500]
                        : null,
                    onTap: () => setState(() => selectedQuestionId = q['_id']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            firstQuestionId == q['_id']
                                ? Icons.star
                                : Icons.star_border,
                            color: firstQuestionId == q['_id']
                                ? Colors.amber
                                : null,
                          ),
                          onPressed: () => setFirstQuestion(
                              q['_id']), // Call function on click
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteQuestionFunc(q['_id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (selectedQuestionId != null) ...[
              const SizedBox(height: 16),
              const Text('Add Answer:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter Answer',
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add), onPressed: addAnswer)
                ],
              ),
              const SizedBox(height: 16),
              const Text('Answers:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: questions
                      .firstWhere((q) => q['_id'] == selectedQuestionId,
                          orElse: () => {'answers': []})['answers']
                      .length,
                  itemBuilder: (context, index) {
                    var question = questions.firstWhere(
                      (q) => q['_id'] == selectedQuestionId,
                      orElse: () => {'answers': []},
                    );

                    var answers = question['answers'] as List;
                    if (answers.isEmpty)
                      return const SizedBox(); // Prevent errors if empty

                    var answer = answers[index];

                    return ListTile(
                      title: Text('${index + 1}. ${answer['answerText']}'),
                      subtitle: DropdownButton<String?>(
                          hint: const Text('Select Next Question'),
                          value: answer['nextQuestionID'] as String?,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: "null",
                              child: Text('None'),
                            ),
                            const DropdownMenuItem<String?>(
                              value: '-',
                              child: Text('Admin'),
                            ),
                            ...questions
                                .where((q) =>
                                    q['_id'] !=
                                    selectedQuestionId) // Exclude the parent question
                                .map((q) => DropdownMenuItem<String?>(
                                      value: q['_id'],
                                      child: Text(q['questionText']),
                                    ))
                                .toList(),
                          ],
                          onChanged: (String? newValue) async {
                            setState(() {
                              answer['nextQuestionID'] =
                                  newValue; // Allowing null
                            });

                            if (selectedQuestionId != null) {
                              await updateNextQuestionForAnswer(
                                  selectedQuestionId!,
                                  answer['_id'],
                                  newValue!);
                            }
                          }),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteAnswerFunc(
                            selectedQuestionId!, answer['_id']),
                      ),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
