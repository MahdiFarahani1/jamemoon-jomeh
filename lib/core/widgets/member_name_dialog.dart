import 'package:flutter/material.dart';

/// The route owns its text controller until the exit animation has finished.
class MemberNameDialog extends StatefulWidget {
  const MemberNameDialog({super.key});

  static Future<String?> show(BuildContext context) => showDialog<String>(
    context: context,
    builder: (_) => const MemberNameDialog(),
  );

  @override
  State<MemberNameDialog> createState() => _MemberNameDialogState();
}

class _MemberNameDialogState extends State<MemberNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('افزودن عضو تیم'),
    content: TextField(
      controller: _name,
      autofocus: true,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(labelText: 'نام بازیکن *'),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('انصراف'),
      ),
      FilledButton(onPressed: _submit, child: const Text('افزودن')),
    ],
  );
}
