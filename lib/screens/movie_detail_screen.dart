// lib/screens/movie_detail_screen.dart (리뷰 작성 폼 연결 완료)

import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/review_form.dart';

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

            //  리뷰 작성 버튼 (로직 추가)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // 키보드 때문에 화면 올라오는 것을 허용
                    builder: (ctx) => ReviewForm(
                      movieId: movie.id, // 영화 ID 전달
                      movieTitle: movie.title, // 영화 제목 전달
                    ),
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

            // TODO: 다음 3주차에서 리뷰 목록이 여기에 표시될 예정
            const SizedBox(height: 30),
            const Text(
              '사용자 리뷰',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Center(child: Text('여기에 리뷰 목록이 실시간으로 표시됩니다.')),
          ],
        ),
      ),
    );
  }
}
