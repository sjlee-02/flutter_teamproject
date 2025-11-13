// lib/main.dart (최종 1주차 + 2주차 인증 기반 완료 버전)

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/movie.dart';
import 'constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'screens/movie_detail_screen.dart';

// Firebase 및 인증 관련 임포트
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_screen.dart';

// main() 함수를 비동기로 변경하고 Firebase 초기화 코드를 추가.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // options: 키워드 제거
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '시네마 로그',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      // home: Firebase 인증 상태에 따라 화면을 전환하는 StreamBuilder
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const SearchMoviesScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class SearchMoviesScreen extends StatefulWidget {
  const SearchMoviesScreen({super.key});

  @override
  State<SearchMoviesScreen> createState() => _SearchMoviesScreenState();
}

class _SearchMoviesScreenState extends State<SearchMoviesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Movie>> _movieData;
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _movieData = ApiService().fetchPopularMovies();
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      if (_currentQuery.isEmpty) {
        setState(() {
          if (_tabController.index == 0) {
            _movieData = ApiService().fetchPopularMovies();
          } else {
            _movieData = ApiService().fetchPopularTvShows();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  //  탭별 검색 로직: 현재 탭에 맞는 API만 호출
  void _performSearch(String query) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isNotEmpty) {
      setState(() {
        _currentQuery = trimmedQuery;

        //  핵심: 탭 인덱스에 따라 검색 함수 분기
        if (_tabController.index == 0) {
          // 영화 탭 (인덱스 0): 영화 전용 검색
          _movieData = ApiService().searchMovies(trimmedQuery);
        } else {
          // 드라마 탭 (인덱스 1): 드라마 전용 검색
          _movieData = ApiService().searchTvShows(trimmedQuery);
        }
      });
    } else {
      // 검색 해제 시: 현재 탭의 인기 목록으로 돌아감
      setState(() {
        _currentQuery = '';
        if (_tabController.index == 0) {
          _movieData = ApiService().fetchPopularMovies();
        } else {
          _movieData = ApiService().fetchPopularTvShows();
        }
      });
    }
  }
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentQuery.isEmpty ? '영화/드라마 목록' : '검색 결과: "$_currentQuery"',
        ),
        bottom: _currentQuery.isEmpty
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '영화'),
                  Tab(text: '드라마'),
                ],
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              FirebaseAuth.instance.signOut(); // 로그아웃 로직
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(
            child: _currentQuery.isEmpty
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContentList(ApiService().fetchPopularMovies()),
                      _buildContentList(ApiService().fetchPopularTvShows()),
                    ],
                  )
                : _buildContentList(_movieData),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(Future<List<Movie>> future) {
    return FutureBuilder<List<Movie>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('불러올 콘텐츠가 없습니다.'));
        } else {
          final List<Movie> movies = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
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
    );
  }
}

class MoviePosterItem extends StatelessWidget {
  final Movie movie;

  const MoviePosterItem({super.key, required this.movie});

  String getPosterUrl(String path) {
    return '$TMDB_IMAGE_BASE_URL$path';
  }

  @override
  Widget build(BuildContext context) {
    // 클릭 이벤트 추가: GestureDetector 위젯으로 감싸서 클릭 이벤트 처리
    return GestureDetector(
      onTap: () {
        // 상세 화면으로 이동 (Movie 객체를 인수로 전달)
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => MovieDetailScreen(movie: movie)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: getPosterUrl(movie.posterPath),
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error_outline),
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
      ),
    );
  }
}
