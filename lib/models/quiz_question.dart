class QuizQuestion {
  String these;
  Map possibleAnswers;
  String answer;
  String source;
  String context;
  String statement;
  List<String> possibleParties;

  QuizQuestion(
      {this.these,
      this.possibleAnswers,
      this.answer,
      this.source,
      this.context,
      this.statement,
      this.possibleParties});

  QuizQuestion.fromJson(Map<String, dynamic> json) {
    these = json['these'];
    possibleAnswers = json['possibleAnswers'] ?? {};
    answer = json['answer'];
    source = json['source'];
    context = json['context'];
    statement = json['statement'];
    possibleParties = json['possibleParties'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['these'] = this.these;
    if (this.possibleAnswers != null) {
      data['possibleAnswers'] = this.possibleAnswers;
    }
    data['answer'] = this.answer;
    data['source'] = this.source;
    data['context'] = this.context;
    data['statement'] = this.statement;
    data['possibleParties'] = this.possibleParties;
    return data;
  }
}
