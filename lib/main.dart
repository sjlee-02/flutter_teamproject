// lib/main.dart

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/movie.dart';
import 'constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '시네마 로그',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const PopularMoviesScreen(),
    );
  }
}

class PopularMoviesScreen extends StatefulWidget {
  const PopularMoviesScreen({super.key});

  @override
  State<PopularMoviesScreen> createState() => _PopularMoviesScreenState();
}

class _PopularMoviesScreenState extends State<PopularMoviesScreen> {
  // 1. FutureBuilder에 사용할 데이터를 가져오는 Future 변수 선언
  late Future<List<Movie>> _popularMovies;

  @override
  void initState() {
    super.initState();
    // 2. 화면이 로드될 때 API 호출 시작
    _popularMovies = ApiService().fetchPopularMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('인기 영화 목록 (1주차 목표)')),
      // 3. FutureBuilder를 사용하여 비동기 데이터 처리
      body: FutureBuilder<List<Movie>>(
        future: _popularMovies,
        builder: (context, snapshot) {
          // 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 에러 발생 시
          else if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          }
          // 데이터가 비어 있을 때 (API 호출 실패 또는 결과 없음)
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('불러올 영화 데이터가 없습니다.'));
          }
          // 데이터 로드 성공 시
          else {
            final List<Movie> movies = snapshot.data!;
            // 4. 데이터를 GridView로 표시 (포스터 기반 리스트)
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 한 줄에 2개의 아이템
                childAspectRatio: 0.7, // 아이템 비율 (세로로 길게)
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final Movie movie = movies[index];
                return MoviePosterItem(movie: movie);
              },
            );
          }
        },
      ),
    );
  }
}

// 영화 포스터를 표시하는 커스텀 위젯
class MoviePosterItem extends StatelessWidget {
  final Movie movie;

  const MoviePosterItem({super.key, required this.movie});

  // 포스터 이미지 URL을 완성하는 함수
  String getPosterUrl(String path) {
    return '$TMDB_IMAGE_BASE_URL$path';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 5. CachedNetworkImage를 사용하여 포스터 이미지 표시
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: getPosterUrl(movie.posterPath),
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.grey[300]), // 로딩 중
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error_outline), // 에러 시
            ),
          ),
        ),
        const SizedBox(height: 5),
        // 6. 영화 제목과 평점 표시
        Text(
          movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          '평점: ${movie.voteAverage.toStringAsFixed(1)}',
          style: TextStyle(fontSize: 12, color: Colors.amber[800]),
        ),
      ],
    );
  }
}
