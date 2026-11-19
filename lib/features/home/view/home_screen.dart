import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/toast_services/toast_service.dart';
import '../../../core/routing/app_routes.dart';
import '../data/model/news_model.dart';
import '../view_model/home_viewmodel.dart';

const Color _newsNavy = Color(0xFF142B4A);
const Color _newsBlue = Color(0xFF3478F6);
const Color _newsCardBackground = Color(0xFFF4F6F9);
const Color _newsText = Color(0xFF202938);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _featuredPageController = PageController(
    viewportFraction: 0.92,
  );
  String _selectedCategory = 'All';
  int _featuredPage = 0;
  HomeViewModel? _observedProvider;
  bool _networkErrorWasShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<HomeViewModel>();
    if (_observedProvider == provider) return;

    _observedProvider?.removeListener(_showNetworkErrorToast);
    _observedProvider = provider;
    provider.addListener(_showNetworkErrorToast);
  }

  @override
  void dispose() {
    _observedProvider?.removeListener(_showNetworkErrorToast);
    _searchController.dispose();
    _featuredPageController.dispose();
    super.dispose();
  }

  void _showNetworkErrorToast() {
    final provider = _observedProvider;
    if (provider == null || !provider.isNetworkError) {
      _networkErrorWasShown = false;
      return;
    }
    if (_networkErrorWasShown || provider.articles.isEmpty) return;

    _networkErrorWasShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_observedProvider, provider)) {
        ToastServices.error('Network lost', 'Please try again.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, newsProvider, _) {
        final location = GoRouterState.of(context).uri.path;
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: switch (location) {
                AppRoutes.search => _buildSearch(context, newsProvider),
                AppRoutes.bookmarks => _buildBookmarks(context, newsProvider),
                _ => _buildHome(context, newsProvider),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHome(BuildContext context, HomeViewModel provider) {
    final filteredArticles = provider.articles
        .where(_matchesSelectedCategory)
        .toList(growable: false);
    final latestArticles = filteredArticles;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical &&
              notification.metrics.extentAfter < 320 &&
              provider.hasMore &&
              !provider.isLoadingMore &&
              provider.errorMessage == null &&
              provider.paginationError == null) {
            unawaited(provider.loadNextPage());
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: _buildHeader(context)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverToBoxAdapter(child: _buildSearchButton(context)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(child: _buildCategoryChips(context)),
            ),
            if (provider.articles.isEmpty && provider.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.articles.isEmpty && provider.errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _StatusMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load news',
                  message: provider.errorMessage!,
                  actionLabel: 'Retry',
                  onAction: provider.refresh,
                ),
              )
            else if (provider.articles.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _StatusMessage(
                  icon: Icons.newspaper_outlined,
                  title: 'No news available',
                  message: 'Pull down to check for the latest headlines.',
                ),
              )
            else if (filteredArticles.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _StatusMessage(
                  icon: Icons.filter_list_off_rounded,
                  title: 'No stories in this category',
                  message: 'Choose another topic to see more news.',
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _FeaturedStoriesCarousel(
                    articles: filteredArticles,
                    pageController: _featuredPageController,
                    currentPage: _featuredPage,
                    isBookmarked: provider.isBookmarked,
                    onBookmark: (article) => _toggleBookmark(provider, article),
                    onOpen: _openArticle,
                    onPageChanged: (page) {
                      if (_featuredPage != page && mounted) {
                        setState(() => _featuredPage = page);
                      }
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Latest News',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : _newsText,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_selectedCategory != 'All') {
                            setState(() => _selectedCategory = 'All');
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View All (${provider.articles.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: _newsBlue,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (latestArticles.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 22),
                    child: Text('You’re all caught up on the latest stories.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final article = latestArticles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CompactArticleCard(
                          article: article,
                          isBookmarked: provider.isBookmarked(article.url),
                          onBookmark: () => _toggleBookmark(provider, article),
                          onOpen: () => _openArticle(article),
                        ),
                      );
                    }, childCount: latestArticles.length),
                  ),
                ),
            ],
            if (provider.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (!provider.isLoadingMore &&
                provider.errorMessage != null &&
                !provider.isNetworkError &&
                provider.articles.isNotEmpty)
              SliverToBoxAdapter(
                child: _PaginationError(
                  message: provider.errorMessage!,
                  actionLabel: 'Retry refresh',
                  onRetry: provider.refresh,
                ),
              ),
            if (!provider.isLoadingMore &&
                provider.paginationError != null &&
                !provider.isNetworkError &&
                provider.articles.isNotEmpty)
              SliverToBoxAdapter(
                child: _PaginationError(
                  message: provider.paginationError!,
                  actionLabel: 'Retry loading more',
                  onRetry: provider.loadNextPage,
                ),
              ),
            if (provider.articles.isNotEmpty &&
                !provider.hasMore &&
                provider.errorMessage == null &&
                provider.paginationError == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Text(
                    'You’re all caught up',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _matchesSelectedCategory(NewsArticle article) {
    if (_selectedCategory == 'All') return true;
    final content =
        '${article.title} ${article.description} ${article.sourceName}'
            .toLowerCase();
    return switch (_selectedCategory) {
      'Technology' =>
        content.contains('technology') ||
            content.contains('tech') ||
            content.contains('ai') ||
            content.contains('software') ||
            content.contains('digital'),
      'Business' =>
        content.contains('business') ||
            content.contains('market') ||
            content.contains('econom') ||
            content.contains('company') ||
            content.contains('finance'),
      'Clean Energy' =>
        content.contains('energy') ||
            content.contains('solar') ||
            content.contains('wind power') ||
            content.contains('renewable') ||
            content.contains('climate'),
      _ => true,
    };
  }

  Widget _buildCategoryChips(BuildContext context) {
    final theme = Theme.of(context);
    const categories = ['All', 'Technology', 'Business', 'Clean Energy'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => _selectCategory(category),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerLow
                : const Color(0xFFF2F4F7),
            selectedColor: _newsBlue,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _greetingForTime(DateTime.now());
    final titleColor = theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _newsNavy,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.newspaper,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Newsly',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHigh
                    : const Color(0xFFE9EDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 19,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          greeting,
          style: theme.textTheme.titleMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here’s your curated news briefing for today.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _greetingForTime(DateTime time) {
    if (time.hour >= 5 && time.hour < 12) return 'Good morning';
    if (time.hour >= 12 && time.hour < 17) return 'Good afternoon';
    if (time.hour >= 17 && time.hour < 21) return 'Good evening';
    return 'Good night';
  }

  Widget _buildSearchButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Theme.of(context).brightness == Brightness.dark
                ? colors.surfaceContainerLow
                : const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.go(AppRoutes.search),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: _newsBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search topics, sources, headlines...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Material(
          color: Theme.of(context).brightness == Brightness.dark
              ? colors.surfaceContainerLow
              : const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showCategoryPicker(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: colors.onSurface,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    const categories = ['All', 'Technology', 'Business', 'Clean Energy'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Filter stories',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final category in categories)
              ListTile(
                title: Text(category),
                trailing: category == _selectedCategory
                    ? const Icon(Icons.check_rounded, color: _newsBlue)
                    : null,
                onTap: () => Navigator.of(context).pop(category),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      _selectCategory(selected);
    }
  }

  void _selectCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _featuredPage = 0;
    });
    if (_featuredPageController.hasClients) {
      _featuredPageController.jumpToPage(0);
    }
  }

  Widget _buildSearch(BuildContext context, HomeViewModel provider) {
    final query = _searchController.text.trim().toLowerCase();
    final articles = provider.articles
        .where((article) {
          return article.title.toLowerCase().contains(query) ||
              article.description.toLowerCase().contains(query) ||
              article.sourceName.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back to Home',
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Text(
                'Search News',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : _newsText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search news...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerLow
                  : _newsCardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: query.isEmpty
                ? const _StatusMessage(
                    icon: Icons.search_rounded,
                    title: 'Search latest headlines',
                    message: 'Enter a keyword to find a loaded article.',
                  )
                : articles.isEmpty
                ? const _StatusMessage(
                    icon: Icons.article_outlined,
                    title: 'No matching articles',
                    message: 'Try a different search term.',
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: articles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return _NewsCard(
                        article: article,
                        isBookmarked: provider.isBookmarked(article.url),
                        onBookmark: () => _toggleBookmark(provider, article),
                        onOpen: () => _openArticle(article),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarks(BuildContext context, HomeViewModel provider) {
    final bookmarks = provider.bookmarks;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bookmarks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurface
                  : _newsText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (provider.bookmarkError != null) ...[
            Text(
              provider.bookmarkError!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (provider.isLoadingBookmarks)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (bookmarks.isEmpty)
            const Expanded(
              child: _StatusMessage(
                icon: Icons.bookmark_border_rounded,
                title: 'No saved articles',
                message: 'Tap the bookmark icon on a story to save it here.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: bookmarks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final article = bookmarks[index];
                  return _NewsCard(
                    article: article,
                    isBookmarked: true,
                    onBookmark: () => _toggleBookmark(provider, article),
                    onOpen: () => _openArticle(article),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleBookmark(
    HomeViewModel provider,
    NewsArticle article,
  ) async {
    try {
      await provider.toggleBookmark(article);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not update bookmark: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _openArticle(NewsArticle article) {
    context.push(AppRoutes.articleDetails, extra: article);
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.article,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onOpen,
  });

  final NewsArticle article;
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      shadowColor: colors.shadow.withValues(alpha: 0.08),
      color: theme.brightness == Brightness.dark
          ? colors.surfaceContainerLow
          : colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                _NewsThumbnail(imageUrl: article.imageUrl),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: colors.surface.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        tooltip: isBookmarked
                            ? 'Remove bookmark'
                            : 'Save bookmark',
                        onPressed: onBookmark,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isBookmarked
                              ? _newsBlue
                              : colors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.public_rounded, size: 15, color: _newsBlue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          article.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _newsBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.publishedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? colors.onSurface
                          : _newsText,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (article.description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  const _FeaturedArticleCard({
    required this.article,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onOpen,
  });

  final NewsArticle article;
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final imageUrl = article.imageUrl;
    final parsedUrl = imageUrl == null ? null : Uri.tryParse(imageUrl);
    final hasImage =
        parsedUrl != null &&
        {'http', 'https'}.contains(parsedUrl.scheme) &&
        parsedUrl.host.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: theme.brightness == Brightness.dark
          ? colors.surfaceContainerLow
          : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.newspaper_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.newspaper_outlined,
                  color: colors.onSurfaceVariant,
                  size: 42,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _newsBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FEATURED STORY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: isBookmarked ? 'Remove bookmark' : 'Save bookmark',
                onPressed: onBookmark,
                color: Colors.white,
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${article.sourceName} · ${article.publishedLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedStoriesCarousel extends StatelessWidget {
  const _FeaturedStoriesCarousel({
    required this.articles,
    required this.pageController,
    required this.currentPage,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onOpen,
    required this.onPageChanged,
  });

  final List<NewsArticle> articles;
  final PageController pageController;
  final int currentPage;
  final bool Function(String url) isBookmarked;
  final ValueChanged<NewsArticle> onBookmark;
  final ValueChanged<NewsArticle> onOpen;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final visibleDotCount = articles.length < 5 ? articles.length : 5;
    final activeDot = articles.length <= visibleDotCount || visibleDotCount <= 1
        ? currentPage
        : (currentPage * (visibleDotCount - 1) / (articles.length - 1)).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth * pageController.viewportFraction - 12;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final cardHeight = cardWidth * 0.68 + 28 * textScale;
        return Column(
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: pageController,
                itemCount: articles.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _FeaturedArticleCard(
                      article: article,
                      isBookmarked: isBookmarked(article.url),
                      onBookmark: () => onBookmark(article),
                      onOpen: () => onOpen(article),
                    ),
                  );
                },
              ),
            ),
            if (visibleDotCount > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(visibleDotCount, (index) {
                  final isActive = index == activeDot;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isActive ? 15 : 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _newsBlue
                          : colors.onSurfaceVariant.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CompactArticleCard extends StatelessWidget {
  const _CompactArticleCard({
    required this.article,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onOpen,
  });

  final NewsArticle article;
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.brightness == Brightness.dark
          ? colors.surfaceContainerLow
          : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: _CompactThumbnail(imageUrl: article.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.sourceName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _newsBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? colors.onSurface
                            : _newsText,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isBookmarked ? 'Remove bookmark' : 'Save bookmark',
                onPressed: onBookmark,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked ? _newsBlue : colors.onSurfaceVariant,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactThumbnail extends StatelessWidget {
  const _CompactThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.newspaper_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    final parsedUrl = imageUrl == null ? null : Uri.tryParse(imageUrl!);
    if (parsedUrl == null ||
        !{'http', 'https'}.contains(parsedUrl.scheme) ||
        parsedUrl.host.isEmpty) {
      return fallback;
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _NewsThumbnail extends StatelessWidget {
  const _NewsThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.newspaper_outlined,
          size: 42,
          color: colors.onSurfaceVariant,
        ),
      ),
    );

    final image = imageUrl;
    final parsedUrl = image == null ? null : Uri.tryParse(image);
    if (image == null ||
        parsedUrl == null ||
        !{'http', 'https'}.contains(parsedUrl.scheme) ||
        parsedUrl.host.isEmpty) {
      return AspectRatio(aspectRatio: 16 / 8.5, child: fallback);
    }

    return AspectRatio(
      aspectRatio: 16 / 8.5,
      child: Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.brightness == Brightness.dark
                  ? colors.onSurfaceVariant
                  : _newsBlue,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? colors.onSurface
                    : _newsText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? colors.onSurfaceVariant
                    : const Color(0xFF687386),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark
                      ? colors.primary
                      : _newsNavy,
                  foregroundColor: theme.brightness == Brightness.dark
                      ? colors.onPrimary
                      : Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaginationError extends StatelessWidget {
  const _PaginationError({
    required this.message,
    required this.actionLabel,
    required this.onRetry,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class NewsArticleDetailsScreen extends StatelessWidget {
  const NewsArticleDetailsScreen({required this.article, super.key});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.42)
        .clamp(260.0, 440.0)
        .toDouble();

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF8F8F3),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            expandedHeight: heroHeight,
            backgroundColor: theme.brightness == Brightness.dark
                ? colors.surface
                : _newsNavy,
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => context.pop(),
              color: Colors.white,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              Selector<HomeViewModel, bool>(
                selector: (context, viewModel) =>
                    viewModel.isBookmarked(article.url),
                builder: (context, isBookmarked, _) => IconButton(
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Save bookmark',
                  onPressed: () => _toggleBookmark(context),
                  color: Colors.white,
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.sourceName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _newsBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? colors.onSurface
                              : _newsText,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        article.publishedLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: colors.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        article.description.isEmpty
                            ? 'No article description is available.'
                            : article.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Original story',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        article.url,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = article.imageUrl;
    final parsedUrl = imageUrl == null ? null : Uri.tryParse(imageUrl);
    final hasImage =
        parsedUrl != null &&
        {'http', 'https'}.contains(parsedUrl.scheme) &&
        parsedUrl.host.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _imageFallback(theme),
          )
        else
          _imageFallback(theme),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x99000000)],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 28,
          child: Text(
            '${article.sourceName} · ${article.publishedLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _imageFallback(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.newspaper_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _toggleBookmark(BuildContext context) async {
    try {
      await context.read<HomeViewModel>().toggleBookmark(article);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not update bookmark: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
