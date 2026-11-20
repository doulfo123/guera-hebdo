import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';
import '../data/content_repository.dart';
import '../data/models.dart';
import 'admin_repository.dart';
import 'admin_scaffold.dart';
import 'admin_widgets.dart';

/// Occupe la moitié de la ligne sur grand écran, toute la largeur sur téléphone.
class _Fx extends StatelessWidget {
  const _Fx({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return narrow ? child : Expanded(child: child);
  }
}

class ArticleEditorPage extends StatefulWidget {
  const ArticleEditorPage({super.key, this.articleId});
  final String? articleId; // null = nouvel article

  @override
  State<ArticleEditorPage> createState() => _ArticleEditorPageState();
}

class _ArticleEditorPageState extends State<ArticleEditorPage> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _body = TextEditingController();
  final _video = TextEditingController();
  final _fbLink = TextEditingController();
  AdminArticle _a = AdminArticle();
  List<Town> _towns = [];
  bool _loading = true;
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _towns = await contentRepo.towns();
      if (widget.articleId != null) {
        final a = await adminRepo.getArticle(widget.articleId!);
        if (a == null) {
          _loadError = 'Article introuvable.';
        } else {
          _a = a;
        }
      }
      _title.text = _a.title;
      _summary.text = _a.summary;
      _body.text = _a.body;
      _video.text = _a.videoUrl ?? '';
    } catch (e) {
      _loadError = friendlyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _body.dispose();
    _video.dispose();
    _fbLink.dispose();
    super.dispose();
  }

  bool _canEdit(Profile me) {
    if (_a.id == null) return true;
    if (me.isStaff) return true;
    return _a.authorId == me.id && (_a.status == 'draft' || _a.status == 'review');
  }

  void _collect() {
    _a
      ..title = _title.text.trim()
      ..summary = _summary.text.trim()
      ..body = _body.text.trim()
      ..videoUrl = _video.text;
  }

  Future<void> _save(Profile me, {String? status, String? note, bool leave = false}) async {
    _collect();
    if (_a.title.length < 3) {
      snack(context, 'Le titre est trop court.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (status != null) _a.status = status;
      if (note != null) _a.reviewNote = note;
      if (status == 'review' || status == 'published') _a.reviewNote = null;
      _a = _a.id == null ? await adminRepo.createArticle(_a) : await adminRepo.updateArticle(_a);
      if (!mounted) return;
      snack(context, 'Enregistré.');
      if (leave) {
        context.go('/admin');
      } else if (widget.articleId == null) {
        context.go('/admin/article/${_a.id}');
      } else {
        setState(() {});
      }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendBack(Profile me) async {
    final c = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text("Message pour l'auteur"),
        content: TextField(controller: c, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Renvoyer')),
        ],
      ),
    );
    c.dispose();
    if (note != null && mounted) await _save(me, status: 'draft', note: note, leave: true);
  }

  void _applyImport(Map<String, dynamic> d) {
    setState(() {
      _title.text = (d['title'] as String?) ?? _title.text;
      _summary.text = (d['summary'] as String?) ?? _summary.text;
      _body.text = (d['body'] as String?) ?? _body.text;
      if (d['video_url'] != null) _video.text = d['video_url'] as String;
      if (d['cover_url'] != null) _a.coverUrl = d['cover_url'] as String;
    });
    snack(
      context,
      d['image_skipped'] == true
          ? "Texte importé. La photo était trop lourde : ajoutez-la à la main. Vérifiez avant d'enregistrer."
          : 'Importé. Relisez, choisissez la rubrique, puis enregistrez.',
    );
  }

  Future<void> _importFb() async {
    final link = _fbLink.text.trim();
    if (link.isEmpty) return;
    setState(() => _busy = true);
    try {
      final d = await adminRepo.importFromFacebook(link);
      if (mounted) _applyImport(d);
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFbPost() async {
    setState(() => _busy = true);
    List<Map<String, dynamic>> posts;
    try {
      posts = await adminRepo.recentFacebookPosts();
    } catch (e) {
      if (mounted) {
        snack(context, friendlyError(e));
        setState(() => _busy = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final id = await showDialog<String>(
      context: context,
      builder: (d) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choisissez une publication de la page', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            Expanded(
              child: posts.isEmpty
                  ? const Center(child: Text('Aucune publication trouvée.'))
                  : ListView.separated(
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final p = posts[i];
                        final msg = ((p['message'] as String?) ?? '').trim();
                        final pic = p['picture'] as String?;
                        return ListTile(
                          leading: pic == null
                              ? const SizedBox(width: 56, height: 56, child: Icon(Icons.article_outlined))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(pic, width: 56, height: 56, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56)),
                                ),
                          title: Text(msg.isEmpty ? '(sans texte)' : msg, maxLines: 3, overflow: TextOverflow.ellipsis),
                          subtitle: Text(((p['date'] as String?) ?? '').split('T').first),
                          onTap: () => Navigator.pop(d, p['id'] as String),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(onPressed: () => Navigator.pop(d), child: const Text('Annuler')),
            ),
          ]),
        ),
      ),
    );
    if (id == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final d = await adminRepo.importFacebookPost(id);
      if (mounted) _applyImport(d);
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareFb() async {
    if (!await confirmDialog(context, 'Publier cet article sur la page Facebook de Guéra Hebdo ?', action: 'Publier sur Facebook')) {
      return;
    }
    setState(() => _busy = true);
    try {
      await adminRepo.publishToFacebook(_a.id!);
      final fresh = await adminRepo.getArticle(_a.id!);
      if (fresh != null) _a.facebookPostId = fresh.facebookPostId;
      if (mounted) snack(context, 'Publié sur Facebook.');
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCover() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
      if (f == null) return;
      setState(() => _busy = true);
      final url = await adminRepo.uploadImage(f, 'articles');
      setState(() => _a.coverUrl = url);
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmDialog(context, 'Supprimer définitivement cet article ?', action: 'Supprimer')) return;
    try {
      await adminRepo.deleteArticle(_a.id!);
      if (mounted) context.go('/admin');
    } catch (e) {
      if (mounted) snack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      current: 'articles',
      title: widget.articleId == null ? 'Nouvel article' : "Modifier l'article",
      builder: (context, me) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_loadError != null) return Center(child: Text(_loadError!));
        final can = _canEdit(me);
        final isNew = _a.id == null;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              StatusBadge(_a.status),
              const Spacer(),
              TextButton(onPressed: () => context.go('/admin'), child: const Text('← Liste')),
            ]),
            if (_a.reviewNote != null && _a.reviewNote!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFFFF4D6),
                child: Text("Message de l'éditeur : ${_a.reviewNote}"),
              ),
            if (!can)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("Cet article n'est plus modifiable par vous.", style: TextStyle(color: Brand.red)),
              ),
            if (can && _a.status != 'published')
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Brand.line),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Importer depuis une publication Facebook',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _fbLink,
                        decoration: const InputDecoration(
                          hintText: 'Collez le lien de la publication',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _busy ? null : _importFb, child: const Text('Importer')),
                  ]),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickFbPost,
                    icon: const Icon(Icons.facebook),
                    label: const Text('Choisir parmi les dernières publications de la page'),
                  ),
                ]),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              enabled: can,
              decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Flex(
              direction: MediaQuery.sizeOf(context).width < 520 ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _Fx(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: kCategories.contains(_a.category) ? _a.category : null,
                  decoration: const InputDecoration(labelText: 'Rubrique', border: OutlineInputBorder()),
                  items: [for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: can ? (v) => setState(() => _a.category = v ?? _a.category) : null,
                ),
              ),
              const SizedBox(width: 12, height: 12),
              _Fx(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  value: _towns.any((t) => t.id == _a.townId) ? _a.townId : null,
                  decoration: const InputDecoration(labelText: 'Localité', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Toute la province')),
                    for (final t in _towns) DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: can ? (v) => setState(() => _a.townId = v) : null,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _summary,
              enabled: can,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Chapeau (résumé)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              enabled: can,
              minLines: 10,
              maxLines: 30,
              decoration: const InputDecoration(
                labelText: 'Texte',
                helperText: 'Séparez les paragraphes par une ligne vide.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _video,
              enabled: can,
              decoration: const InputDecoration(
                labelText: 'Lien de la vidéo Facebook (facultatif)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              if (_a.coverUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(_a.coverUrl!, width: 120, height: 80, fit: BoxFit.cover),
                ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: can && !_busy ? _pickCover : null,
                icon: const Icon(Icons.image_outlined),
                label: Text(_a.coverUrl == null ? 'Ajouter une photo' : 'Changer la photo'),
              ),
              if (_a.coverUrl != null && can)
                IconButton(
                  tooltip: 'Retirer la photo',
                  onPressed: () => setState(() => _a.coverUrl = null),
                  icon: const Icon(Icons.close),
                ),
            ]),
            const SizedBox(height: 24),
            if (can)
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton(
                  onPressed: _busy ? null : () => _save(me),
                  child: const Text('Enregistrer'),
                ),
                if (_a.status == 'draft')
                  OutlinedButton(
                    onPressed: _busy ? null : () => _save(me, status: 'review', leave: true),
                    child: const Text('Envoyer en relecture'),
                  ),
                if (me.isStaff && _a.status != 'published')
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Brand.red),
                    onPressed: _busy ? null : () => _save(me, status: 'published', leave: true),
                    child: const Text('Publier'),
                  ),
                if (me.isStaff && _a.status == 'review')
                  OutlinedButton(
                    onPressed: _busy ? null : () => _sendBack(me),
                    child: const Text("Renvoyer à l'auteur"),
                  ),
                if (me.isStaff && _a.status == 'published')
                  OutlinedButton(
                    onPressed: _busy ? null : () => _save(me, status: 'draft', leave: true),
                    child: const Text('Dépublier'),
                  ),
                if (me.isStaff && _a.status != 'archived' && !isNew)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _save(me, status: 'archived', leave: true),
                    child: const Text('Archiver'),
                  ),
                if (me.isStaff && _a.status == 'published')
                  _a.facebookPostId != null
                      ? const Chip(avatar: Icon(Icons.check, size: 16), label: Text('Déjà sur Facebook'))
                      : OutlinedButton.icon(
                          onPressed: _busy ? null : _shareFb,
                          icon: const Icon(Icons.facebook),
                          label: const Text('Publier sur Facebook'),
                        ),
                if (!isNew && (me.isStaff || _a.status == 'draft'))
                  TextButton(
                    onPressed: _busy ? null : _delete,
                    child: const Text('Supprimer', style: TextStyle(color: Brand.red)),
                  ),
              ]),
          ],
        );
      },
    );
  }
}
