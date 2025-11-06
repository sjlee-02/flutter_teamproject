// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/movie.dart';

class ApiService {
  // 인기 영화 목록을 가져오는 비동기 함수
  Future<List<Movie>> fetchPopularMovies() async {
    // URL 생성 (인기 영화, 한국어 설정, API 키 포함)
    final url = Uri.parse(
      '$TMDB_BASE_URL/movie/popular?api_key=$TMDB_API_KEY&language=ko-KR',
    );

    try {
      final response = await http.get(url); // API 요청

      if (response.statusCode == 200) {
        // 성공 시: JSON 디코딩 및 한글 깨짐 방지
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final List results = data['results'];

        // JSON 리스트를 Movie 객체 리스트로 변환
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        // 실패: 오류 처리
        throw Exception(
          'Failed to load movies: Status Code ${response.statusCode}',
        );
      }
    } catch (e) {
      // 네트워크 에러 처리
      print('네트워크 에러 발생: $e');
      // 에러 발생 시 빈 리스트를 반환하여 앱이 멈추지 않게 함
      return [];
    }
  }
}
