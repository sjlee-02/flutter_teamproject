// lib/services/api_service.dart
// TMDB 서버에 요청을 보내고 영화, TV 드라마 데이터를 가져오고 통합 검색하는 로직

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/movie.dart';

class ApiService {
  //  인기 영화 목록을 가져오는 비동기 함수
  Future<List<Movie>> fetchPopularMovies() async {
    final url = Uri.parse(
      '$TMDB_BASE_URL/movie/popular?api_key=$TMDB_API_KEY&language=ko-KR',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final List results = data['results'];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load popular movies: Status Code ${response.statusCode}',
        );
      }
    } catch (e) {
      print('인기 영화 네트워크 에러 발생: $e');
      return [];
    }
  }

  //  인기 TV 드라마 목록을 가져오는 비동기 함수
  Future<List<Movie>> fetchPopularTvShows() async {
    final url = Uri.parse(
      '$TMDB_BASE_URL/tv/popular?api_key=$TMDB_API_KEY&language=ko-KR',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final List results = data['results'];

        // TV 드라마도 Movie 모델을 사용하여 변환
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load popular TV shows: Status Code ${response.statusCode}',
        );
      }
    } catch (e) {
      print('인기 드라마 네트워크 에러 발생: $e');
      return [];
    }
  }

  //  통합 검색 (영화와 TV 드라마 동시 검색) 함수 (search/multi 엔드포인트)
  Future<List<Movie>> searchMulti(String query) async {
    if (query.isEmpty) {
      return []; // 검색어가 없으면 요청하지 않고 빈 리스트 반환
    }

    final url = Uri.parse(
      '$TMDB_BASE_URL/search/multi?api_key=$TMDB_API_KEY&language=ko-KR&query=$query',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final List results = data['results'];

        // 검색 결과 중 'movie'와 'tv' 타입만 필터링하여 반환
        return results
            .where(
              (json) =>
                  json['media_type'] == 'movie' || json['media_type'] == 'tv',
            )
            .map((json) => Movie.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to search multi: Status Code ${response.statusCode}',
        );
      }
    } catch (e) {
      print('통합 검색 네트워크 에러 발생: $e');
      return [];
    }
  }
}
