// lib/main.dart (최종 1주차 목표: 탭 및 통합 검색 완료 버전)

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

//  TickerProviderStateMixin 추가: TabController 사용을 위해 필수
class _SearchMoviesScreenState extends State<SearchMoviesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // _movieData는 검색 결과를 담는 데 사용됩니다. 인기 목록은 TabBarView 내부에서 직접 호출합니다.
  late Future<List<Movie>> _movieData;
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    // TabController 초기화 (길이 2: 영화, 드라마)
    _tabController = TabController(length: 2, vsync: this);

    // 초기에는 영화 목록을 로드하도록 설정 (TabController 초기 인덱스 0)
    _movieData = ApiService().fetchPopularMovies();

    //  탭 변경 시 데이터를 새로고침하는 리스너 추가
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      // 탭 변경이 완료되었을 때만 실행
      if (_currentQuery.isEmpty) {
        // 검색 중이 아닐 때만 탭 변경에 따른 데이터 로드
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

  // 검색 로직 실행 함수 (Enter를 누르거나 검색 버튼을 눌렀을 때 호출됨)
  void _performSearch(String query) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isNotEmpty) {
      //  검색어가 있으면 통합 검색 호출
      setState(() {
        _currentQuery = trimmedQuery;
        _movieData = ApiService().searchMulti(trimmedQuery);
      });
    } else {
      //  검색 해제 시
      setState(() {
        _currentQuery = '';
        // 현재 활성화된 탭의 인기 목록으로 돌아감
        if (_tabController.index == 0) {
          _movieData = ApiService().fetchPopularMovies();
        } else {
          _movieData = ApiService().fetchPopularTvShows();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 탭바와 목록을 표시할 Future를 결정합니다.
    final Future<List<Movie>> currentListFuture = _currentQuery.isNotEmpty
        ? _movieData // 검색 중일 때
        : _tabController.index == 0
        ? ApiService()
              .fetchPopularMovies() // 영화 탭일 때
        : ApiService().fetchPopularTvShows(); // 드라마 탭일 때

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentQuery.isEmpty ? '영화/드라마 목록' : '검색 결과: "$_currentQuery"',
        ),
        //  검색 중이 아닐 때만 탭바를 보여줍니다.
        bottom: _currentQuery.isEmpty
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '영화'),
                  Tab(text: '드라마'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          //  검색 필드 UI
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
                    _performSearch(''); // 검색 해제
                  },
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),

          //  검색 결과 또는 탭뷰 영역
          Expanded(
            child: _currentQuery.isEmpty
                ? TabBarView(
                    //  검색 중이 아닐 때: TabBarView를 통해 각 탭의 내용을 보여줌
                    controller: _tabController,
                    children: [
                      _buildContentList(
                        ApiService().fetchPopularMovies(),
                      ), // 영화 탭
                      _buildContentList(
                        ApiService().fetchPopularTvShows(),
                      ), // 드라마 탭
                    ],
                  )
                : _buildContentList(_movieData), // 검색 중일 때는 통합 검색 결과 표시
          ),
        ],
      ),
    );
  }

  // ⭐️ 데이터 로딩 및 목록 표시를 담당하는 별도 위젯 함수
  Widget _buildContentList(Future<List<Movie>> future) {
    return FutureBuilder<List<Movie>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('불러올 콘텐츠가 없습니다.'));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: getPosterUrl(movie.posterPath),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[300]),
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
    );
  }
}
