import 'package:flutter/material.dart';

class ChatbotManagerScreen extends StatefulWidget {
  @override
  _ChatbotManagerScreenState createState() => _ChatbotManagerScreenState();
}

class _ChatbotManagerScreenState extends State<ChatbotManagerScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  Map<String, List<String>> chatbotData = {};
  String? selectedQuestion;

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void addQuestion() {
    String question = _questionController.text.trim();
    if (question.isNotEmpty && !chatbotData.containsKey(question)) {
      setState(() {
        chatbotData[question] = [];
        selectedQuestion = question;
      });
      _questionController.clear();
    }
  }

  void addAnswer() {
    String answer = _answerController.text.trim();
    if (selectedQuestion != null && answer.isNotEmpty) {
      setState(() {
        chatbotData[selectedQuestion]!.add(answer);
      });
      _answerController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insert New Question:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter question',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addQuestion,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Insert Answer for Selected Question:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _answerController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter answer',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addAnswer,
                )
              ],
            ),
            SizedBox(height: 16),
            Text('Questions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: chatbotData.keys.length,
                itemBuilder: (context, index) {
                  String question = chatbotData.keys.elementAt(index);
                  return ListTile(
                    title: Text(question),
                    onTap: () {
                      setState(() {
                        selectedQuestion = question;
                      });
                    },
                    selected: selectedQuestion == question,
                  );
                },
              ),
            ),
            if (selectedQuestion != null) ...[
              SizedBox(height: 16),
              Text('Answers for "$selectedQuestion":',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: chatbotData[selectedQuestion]!.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(chatbotData[selectedQuestion]![index]),
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
