// lib/screens/movie_detail_screen.dart (리뷰 작성 폼 및 리뷰 목록 연결 완료)

import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/review_form.dart'; // ⭐️ 2주차: 리뷰 폼 임포트
import '../widgets/review_list.dart'; // ⭐️ 3주차: 리뷰 목록 임포트

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  String getPosterUrl(String path) {
    return '$TMDB_IMAGE_BASE_URL$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 포스터 이미지
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: getPosterUrl(movie.posterPath),
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(height: 300, color: Colors.grey[300]),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, size: 300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. 제목 및 평점
            Text(
              movie.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'TMDB 평점: ${movie.voteAverage.toStringAsFixed(1)} / 10',
              style: const TextStyle(fontSize: 16, color: Colors.amber),
            ),
            const SizedBox(height: 20),

            // 3. 개요 (Overview)
            const Text(
              '개요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(movie.overview, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),

            // 4. 리뷰 작성 버튼 (2주차 기능)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) =>
                        ReviewForm(movieId: movie.id, movieTitle: movie.title),
                  );
                },
                icon: const Icon(Icons.rate_review),
                label: const Text('리뷰 작성하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            // ⭐️ 5. 3주차 목표: 리뷰 목록 표시 ⭐️
            const SizedBox(height: 30),
            const Text(
              '사용자 리뷰',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ReviewList 위젯을 삽입하고 movieId를 전달합니다.
            ReviewList(movieId: movie.id),
          ],
        ),
      ),
    );
  }
}
