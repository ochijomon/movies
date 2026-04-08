import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'rating_badge.dart';

/// Card widget for displaying a movie in a grid or list.
class MovieCard extends StatelessWidget {
  final String title;
  final String year;
  final String genre;
  final double rating;
  final int reviewCount;
  final String? posterUrl;
  final VoidCallback? onTap;

  const MovieCard({
    super.key,
    required this.title,
    required this.year,
    required this.genre,
    required this.rating,
    required this.reviewCount,
    this.posterUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster area
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  image: posterUrl != null
                      ? DecorationImage(
                          image: NetworkImage(posterUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: posterUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.local_movies_outlined,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        year,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          genre,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      RatingBadge(rating: rating),
                      const Spacer(),
                      Icon(
                        Icons.rate_review_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$reviewCount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

/// Row widget for displaying a movie in a table/list view.
class MovieTableRow extends StatelessWidget {
  final String title;
  final String year;
  final String genre;
  final double rating;
  final int reviewCount;
  final String? posterUrl;
  final VoidCallback? onTap;

  const MovieTableRow({
    super.key,
    required this.title,
    required this.year,
    required this.genre,
    required this.rating,
    required this.reviewCount,
    this.posterUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                image: posterUrl != null
                    ? DecorationImage(
                        image: NetworkImage(posterUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: posterUrl == null
                  ? const Icon(Icons.local_movies_outlined,
                      size: 20, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            // Title & genre
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    genre,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Year
            SizedBox(
              width: 60,
              child: Text(
                year,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Rating
            SizedBox(
              width: 70,
              child: RatingBadge(rating: rating),
            ),
            // Reviews
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  const Icon(Icons.rate_review_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '$reviewCount',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Action
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded,
                  color: AppColors.textSecondary, size: 20),
              onPressed: onTap,
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
