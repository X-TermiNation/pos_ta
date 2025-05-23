import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:ta_pos/view-model-flutter/chatbot_controller.dart';

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
  String? firstQuestionId;

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
        fetchQuestions();
      }
    }
  }

  Future<void> addAnswer() async {
    if (selectedQuestionId == null) return;
    String answerText = _answerController.text.trim();
    if (answerText.isNotEmpty) {
      await insertAnswer(selectedQuestionId!, answerText, null);
      _answerController.clear();
      fetchQuestions();
    }
  }

  Future<void> deleteQuestionFunc(String questionId) async {
    await deleteQuestion(questionId);
    setState(() {
      selectedQuestionId = null;
    });
    fetchQuestions();
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
    if (selectedQuestionId.isEmpty) return;
    bool success =
        await updateNextQuestion(selectedQuestionId, answerId, newQuestionId);
    if (success) fetchQuestions();
  }

  Future<void> setFirstQuestion(String questionId) async {
    if (firstQuestionId == questionId) return;

    bool success = await updateFirstQuestionID(questionId);
    if (success) {
      setState(() {
        firstQuestionId = questionId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatbot Manager')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Question:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Enter question',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: addQuestion,
                    ),
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
                        onTap: () =>
                            setState(() => selectedQuestionId = q['_id']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFirstQuestion
                                    ? Icons.star
                                    : Icons.star_border,
                                color: isFirstQuestion ? Colors.amber : null,
                              ),
                              onPressed: () => setFirstQuestion(q['_id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
                  TextField(
                    controller: _answerController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Enter answer',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: addAnswer,
                      ),
                    ),
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
                            orElse: () => {'answers': []});
                        var answers = question['answers'] as List;
                        if (answers.isEmpty) return const SizedBox();
                        var answer = answers[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title:
                                  Text('${index + 1}. ${answer['answerText']}'),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteAnswerFunc(
                                    selectedQuestionId!, answer['_id']),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: DropdownButton<String?>(
                                isExpanded: true,
                                hint: const Text('Select Next Question'),
                                value: answer['nextQuestionID'] as String?,
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: "null",
                                    child: Text('None'),
                                  ),
                                  const DropdownMenuItem<String?>(
                                    value: "-",
                                    child: Text('Admin'),
                                  ),
                                  ...questions
                                      .where(
                                          (q) => q['_id'] != selectedQuestionId)
                                      .map((q) => DropdownMenuItem<String?>(
                                            value: q['_id'],
                                            child: Text(q['questionText']),
                                          ))
                                      .toList(),
                                ],
                                onChanged: (String? newValue) async {
                                  setState(() {
                                    answer['nextQuestionID'] = newValue;
                                  });
                                  if (selectedQuestionId != null &&
                                      newValue != null) {
                                    await updateNextQuestionForAnswer(
                                        selectedQuestionId!,
                                        answer['_id'],
                                        newValue);
                                  }
                                },
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
