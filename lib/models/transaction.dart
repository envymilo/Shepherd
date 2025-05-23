import 'package:shepherd_mo/models/group.dart';

class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final String type;
  final String approvalStatus;
  final String? relevantID;
  final String groupID;
  final Group group;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.approvalStatus,
    required this.groupID,
    this.relevantID,
    required this.group,
  });

  // Factory method to create an Expense instance from a JSON object
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      approvalStatus: json['approvalStatus'],
      groupID: json['groupID'],
      relevantID: json['relevantID'],
      group: Group.fromJson(json['group']),
    );
  }
}
