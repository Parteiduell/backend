class QuizThese {
  String these;
  Map statements;
  String source;
  String context;

  QuizThese({this.these, this.statements, this.source, this.context});

  QuizThese.fromJson(Map<String, dynamic> json) {
    these = json['these'];
    statements = json['statements'] ?? {};
    source = json['source'];
    context = json['context'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['these'] = this.these;
    if (this.statements != null) {
      data['statements'] = this.statements;
    }
    data['source'] = this.source;
    data['context'] = this.context;
    return data;
  }
}
