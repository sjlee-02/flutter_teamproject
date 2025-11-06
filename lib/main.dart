// lib/main.dart
//통신 상태를 처리하며 영화 포스터 목록을 화면에 표시하는 메인 화면

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
      home: const SearchMoviesScreen(),
    );
  }
}

class SearchMoviesScreen extends StatefulWidget {
  const SearchMoviesScreen({super.key});

  @override
  State<SearchMoviesScreen> createState() => _SearchMoviesScreenState();
}

class _SearchMoviesScreenState extends State<SearchMoviesScreen> {
  //  현재 화면에 표시할 데이터를 관리하는 Future 변수
  late Future<List<Movie>> _movieData;
  //  검색어 입력을 받을 TextEditingController
  final TextEditingController _searchController = TextEditingController();
  //  현재 검색어를 저장하는 변수 (빈 문자열이면 인기 목록)
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    // 초기에는 인기 영화 목록을 가져옵니다.
    _movieData = ApiService().fetchPopularMovies();
  }

  //  검색 로직을 실행하는 함수
  void _performSearch(String query) {
    // 공백 제거 후 검색어 확인
    final trimmedQuery = query.trim();

    if (trimmedQuery.isNotEmpty) {
      // 검색어가 있으면 searchMovies 호출
      setState(() {
        _currentQuery = trimmedQuery;
        _movieData = ApiService().searchMovies(trimmedQuery);
      });
    } else {
      // 검색어가 비어있으면 다시 인기 목록을 보여줍니다.
      setState(() {
        _currentQuery = '';
        _movieData = ApiService().fetchPopularMovies();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentQuery.isEmpty ? '인기 영화 목록' : '검색 결과: "$_currentQuery"',
        ),
      ),
      body: Column(
        children: [
          //  검색 필드 UI 추가 (사용자 입력)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '영화/드라마 제목 검색 ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    // 검색 필드 초기화 및 인기 목록 복원
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
              onSubmitted: _performSearch, //  엔터키 입력 시 검색 실행
            ),
          ),
          //  검색 결과를 표시할 영역 (확장)
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _movieData,
              builder: (context, snapshot) {
                // 로딩 중일 때
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // 에러 발생 시
                else if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: ${snapshot.error}'));
                }
                // 데이터가 비어 있을 때
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      _currentQuery.isEmpty
                          ? '불러올 영화 데이터가 없습니다.'
                          : '검색 결과가 없습니다. 다시 시도해 보세요.',
                    ),
                  );
                }
                // 데이터 로드 성공 시
                else {
                  final List<Movie> movies = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final Movie movie = movies[index];
                      // MoviePosterItem 위젯을 사용하여 각 아이템 표시
                      return MoviePosterItem(movie: movie);
                    },
                  );
                }
              },
            ),
          ),
        ],
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
