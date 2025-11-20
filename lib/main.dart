// lib/main.dart (최종 다크 테마 디자인 및 새로고침 버그 수정 완료 버전)

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '시네마 로그',
      // 앱 전체의 기본 테마를 다크 모드로 설정
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // 텍스트 필드 기본 스타일 조정
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIconColor: Colors.white54,
          suffixIconColor: Colors.white54,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
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

  void _performSearch(String query) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isNotEmpty) {
      setState(() {
        _currentQuery = trimmedQuery;

        if (_tabController.index == 0) {
          _movieData = ApiService().searchMovies(trimmedQuery);
        } else {
          _movieData = ApiService().searchTvShows(trimmedQuery);
        }
      });
    } else {
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

  //  새로고침 로직: 검색 상태를 고려하여 수정
  Future<void> _onRefresh() async {
    if (_currentQuery.isEmpty) {
      //  인기 목록을 보고 있을 때
      setState(() {
        if (_tabController.index == 0) {
          _movieData = ApiService().fetchPopularMovies();
        } else {
          _movieData = ApiService().fetchPopularTvShows();
        }
      });
    } else {
      // 검색 중일 때: 현재 쿼리로 검색을 다시 실행
      setState(() {
        if (_tabController.index == 0) {
          _movieData = ApiService().searchMovies(_currentQuery);
        } else {
          _movieData = ApiService().searchTvShows(_currentQuery);
        }
      });
    }
    // 데이터 로딩이 완료될 때까지 기다림
    await _movieData;
  }
  // -------------------------------------------------------------

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃 확인', style: TextStyle(color: Colors.white)),
        content: const Text(
          '시네마 로그에서 정말 로그아웃 하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        backgroundColor: Colors.grey[850],
        actions: <Widget>[
          TextButton(
            child: const Text('취소', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentQuery.isEmpty ? '시네마 로그' : '검색 결과: "$_currentQuery"',
          style: const TextStyle(color: Colors.white),
        ),
        bottom: _currentQuery.isEmpty
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue[700],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: '영화'),
                  Tab(text: '드라마'),
                ],
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _showLogoutConfirmationDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '영화/드라마 제목 검색 ...',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
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
                      RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: Colors.white,
                        child: _buildContentList(
                          ApiService().fetchPopularMovies(),
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: Colors.white,
                        child: _buildContentList(
                          ApiService().fetchPopularTvShows(),
                        ),
                      ),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Colors.white,
                    child: _buildContentList(_movieData),
                  ),
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
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '에러 발생: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '불러올 콘텐츠가 없습니다.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        } else {
          final List<Movie> movies = snapshot.data!;
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
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
    return GestureDetector(
      onTap: () {
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
                    Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error_outline, color: Colors.redAccent),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '평점: ${movie.voteAverage.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 12, color: Colors.amber[600]),
          ),
        ],
      ),
    );
  }
}
