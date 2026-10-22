import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(DiverStoreScope.of(context).ensureCommunityPostsLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final posts = store.posts;
        return adminScreenShell(
          embedded: widget.embedded,
          title: l10n.adminPostsTitle,
          body: RefreshIndicator(
            onRefresh: () async {
              await store.refreshCommunityPosts();
              while (store.postsHasMore) {
                await store.loadMoreCommunityPosts();
              }
            },
            child: posts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.4,
                        child: Center(child: Text(l10n.adminEmptyPosts)),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: posts.length + (store.postsHasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= posts.length) {
                        return TextButton(
                          onPressed: () =>
                              unawaited(store.loadMoreCommunityPosts()),
                          child: const Text('Load more'),
                        );
                      }
                      return _PostModerationTile(post: posts[index]);
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _PostModerationTile extends StatelessWidget {
  const _PostModerationTile({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final typeLabel = post.type == CommunityPostType.buddy
        ? l10n.adminPostTypeBuddy
        : l10n.adminPostTypeTour;

    return Card(
      child: ListTile(
        leading: Icon(
          post.type == CommunityPostType.buddy
              ? Icons.groups_2
              : Icons.storefront,
        ),
        title: Text(post.title),
        subtitle: Text(
          '$typeLabel · ${post.authorName}\n${post.subtitle}'
          '${post.hidden ? '\n${l10n.adminPostHidden}' : ''}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: post.hidden ? l10n.adminUnhidePost : l10n.adminHidePost,
              onPressed: () => store.setPostHidden(
                postId: post.id,
                hidden: !post.hidden,
              ),
              icon: Icon(
                post.hidden ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            IconButton(
              tooltip: l10n.adminDeletePost,
              onPressed: () => store.deletePost(post.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
