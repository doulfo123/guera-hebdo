import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/content_repository.dart';
import '../data/models.dart';
import '../data/voter_key.dart';

/// Sondage « La voix du Guéra » : un vote par appareil, résultats réels après le vote.
class PollCard extends StatefulWidget {
  const PollCard({super.key});

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  late final Future<Poll?> _poll = contentRepo.activePoll();
  String? _picked;
  Map<String, int>? _results;
  bool _restored = false;

  Future<void> _restore(Poll poll) async {
    if (_restored) return;
    _restored = true;
    final saved = await savedVote(poll.id);
    if (saved == null) return;
    final results = await _safeResults(poll.id);
    if (!mounted) return;
    setState(() {
      _picked = saved;
      _results = results;
    });
  }

  Future<Map<String, int>?> _safeResults(String pollId) async {
    try {
      return await contentRepo.pollResults(pollId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _vote(Poll poll, PollOption option) async {
    try {
      await contentRepo.vote(optionId: option.id, voterKey: await voterKey());
      await saveVote(poll.id, option.id);
      final results = await _safeResults(poll.id);
      if (!mounted) return;
      setState(() {
        _picked = option.id;
        _results = results;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote impossible pour le moment. Réessayez plus tard.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Poll?>(
      future: _poll,
      builder: (context, snap) {
        final poll = snap.data;
        if (poll == null) return const SizedBox.shrink();
        _restore(poll);
        final results = _results;
        final total = results == null
            ? 0
            : results.values.fold<int>(0, (a, b) => a + b);
        return Container(
          width: double.infinity,
          color: Brand.navy,
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Brand.yellow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LA VOIX DU GUÉRA',
                  style: TextStyle(
                    color: Brand.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                poll.question,
                style: displayStyle(34, color: Colors.white, height: 1.02),
              ),
              const SizedBox(height: 14),
              for (final o in poll.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OptionButton(
                    option: o,
                    selected: _picked == o.id,
                    percent: (results != null && total > 0)
                        ? ((results[o.id] ?? 0) * 100 / total).round()
                        : null,
                    onTap: () => _vote(poll, o),
                  ),
                ),
              if (_picked != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    results == null
                        ? 'Merci pour votre vote !'
                        : 'Merci pour votre vote ! $total ${total > 1 ? 'votes' : 'vote'} au total. '
                            'Vous pouvez changer de réponse.',
                    style: const TextStyle(
                      color: Color(0xFFC9D6EE),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.selected,
    required this.percent,
    required this.onTap,
  });

  final PollOption option;
  final bool selected;
  final int? percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        alignment: Alignment.centerLeft,
        foregroundColor: selected ? Brand.navy : Colors.white,
        backgroundColor: selected ? Colors.white : Colors.transparent,
        side: const BorderSide(color: Colors.white, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${option.letter} · ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: option.label),
                ],
              ),
              style: const TextStyle(fontSize: 16, height: 1.3),
            ),
          ),
          if (percent != null)
            Text(
              '$percent %',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
        ],
      ),
    );
  }
}
