// lib/models/movie.dart

class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final double voteAverage;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.voteAverage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      // 제목이 없으면 '제목 없음'
      title: json['title'] ?? json['name'] ?? '제목 없음',
      overview: json['overview'] ?? '개요 없음',
      // 포스터 경로만 저장
      posterPath: json['poster_path'] ?? '',
      // API에서 받은 평점을 double 타입으로 변환
      voteAverage: (json['vote_average'] as num).toDouble(),
    );
  }
}
