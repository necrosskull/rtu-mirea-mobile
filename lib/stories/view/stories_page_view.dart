import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:rtu_mirea_app/common/utils/utils.dart';
import 'package:rtu_mirea_app/domain/entities/story.dart';
import 'package:rtu_mirea_app/presentation/widgets/buttons/primary_button.dart';
import 'package:story/story.dart';
import 'package:rtu_mirea_app/presentation/typography.dart';

class StoriesPageView extends StatefulWidget {
  const StoriesPageView({
    Key? key,
    required this.stories,
    required this.storyIndex,
  }) : super(key: key);

  final List<Story> stories;
  final int storyIndex;

  @override
  State<StoriesPageView> createState() => _StoriesPageViewState();
}

class _StoriesPageViewState extends State<StoriesPageView> {
  int _prevStoryIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: DismissiblePage(
        onDismissed: () => context.pop(),
        isFullScreen: false,
        direction: DismissiblePageDismissDirection.vertical,
        backgroundColor: Colors.transparent,
        child: OverflowBox(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Hero(
                tag: widget.stories[widget.storyIndex].title,
                child: StoryPageView(
                  indicatorDuration:
                      const Duration(seconds: 6, milliseconds: 500),
                  initialPage: widget.storyIndex,
                  itemBuilder: (context, pageIndex, storyIndex) {
                    if (pageIndex != _prevStoryIndex) {
                      _prevStoryIndex = pageIndex;
                      FirebaseAnalytics.instance
                          .logEvent(name: 'view_story', parameters: {
                        'story_title': widget.stories[pageIndex].title,
                      });
                    }
                    final author = widget.stories[pageIndex].author;
                    final page = widget.stories[pageIndex].pages[storyIndex];
                    return _buildStoryPage(author, page);
                  },
                  gestureItemBuilder: (context, pageIndex, storyIndex) {
                    return _buildGestureItems(pageIndex, storyIndex);
                  },
                  pageLength: widget.stories.length,
                  storyLength: (int pageIndex) {
                    return widget.stories[pageIndex].pages.length;
                  },
                  onPageLimitReached: () => context.pop(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPage(Author author, StoryPage page) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: page.media.formats != null
                ? ExtendedImage.network(
                    StrapiUtils.getLargestImageUrl(page.media.formats!),
                    fit: BoxFit.cover,
                    cache: true,
                  )
                : ExtendedImage.network(
                    page.media.url,
                    fit: BoxFit.cover,
                    cache: true,
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 44, left: 8),
          child: Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: author.logo.formats != null
                        ? NetworkImage(author.logo.formats!.small != null
                            ? author.logo.formats!.small!.url
                            : author.logo.formats!.thumbnail.url)
                        : NetworkImage(author.logo.url),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black
                          .withOpacity(0.5), // Adjust the opacity as needed
                      BlendMode.srcATop,
                    ),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Material(
                type: MaterialType.transparency,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.5),
                      ],
                    ).createShader(
                      Rect.fromLTRB(
                        0,
                        0,
                        rect.width,
                        rect.height,
                      ),
                    );
                  },
                  blendMode: BlendMode.srcATop,
                  child: Text(
                    author.name,
                    style: AppTextStyle.bodyBold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 105,
          left: 24,
          right: 24,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (page.title != null)
                  Column(
                    children: [
                      Text(
                        page.title!,
                        style: AppTextStyle.h4,
                      ),
                      const SizedBox(height: 16)
                    ],
                  ),
                if (page.text != null)
                  Text(
                    page.text!,
                    style: AppTextStyle.bodyBold,
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGestureItems(int pageIndex, int storyIndex) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 42),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                padding: EdgeInsets.zero,
                color: Colors.white,
                icon: const Icon(Icons.close),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: List.generate(
              widget.stories[pageIndex].pages[storyIndex].actions.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PrimaryButton(
                  text: widget.stories[pageIndex].pages[storyIndex]
                      .actions[index].title,
                  onClick: () {
                    launchUrlString(widget.stories[pageIndex].pages[storyIndex]
                        .actions[index].url);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}