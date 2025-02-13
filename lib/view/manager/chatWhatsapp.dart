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

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    var fetchedQuestions = await getAllQuestions();
    if (fetchedQuestions != null && fetchedQuestions is List) {
      setState(() {
        questions = List<Map<String, dynamic>>.from(fetchedQuestions);
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

  Future<void> deleteQuestion(String questionId) async {
    await deleteQuestion(questionId);
    setState(() {
      selectedQuestionId = null;
    });
    fetchQuestions(); // Refresh list
  }

  Future<void> deleteAnswer(String questionId, String answerId) async {
    await deleteAnswer(questionId, answerId);
    fetchQuestions(); // Refresh list
  }

  Future<void> updateNextQuestionForAnswer(
      String answerId, String? newQuestionId) async {
    if (selectedQuestionId == null) return;
    bool success =
        await updateNextQuestion(selectedQuestionId!, answerId, newQuestionId!);
    if (success) fetchQuestions(); // Refresh list
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
                  return ListTile(
                    title: Text('${index + 1}. ${q['questionText']}'), // FIXED
                    tileColor: selectedQuestionId == q['_id']
                        ? Colors.grey[500]
                        : null,
                    onTap: () => setState(() => selectedQuestionId = q['_id']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteQuestion(q['_id']),
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
                      title: Text(
                          '${index + 1}. ${answer['answerText']}'), // ✅ Correct key
                      subtitle: DropdownButton<String?>(
                        hint: const Text('Select Next Question'),
                        value: answer['nextQuestionID']
                            as String?, // ✅ Use correct key
                        items: [
                          const DropdownMenuItem<String?>(
                              value: null, child: Text('None')),
                          ...questions
                              .where((q) =>
                                  q['_id'] !=
                                  selectedQuestionId) // ✅ Filter out current question
                              .map((q) => DropdownMenuItem<String?>(
                                    value: q['_id'],
                                    child: Text(
                                        q['questionText']), // ✅ Correct key
                                  ))
                              .toList(),
                        ],
                        onChanged: (newValue) => updateNextQuestionForAnswer(
                            answer['_id'], newValue),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            deleteAnswer(selectedQuestionId!, answer['_id']),
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
