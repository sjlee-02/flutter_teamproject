// lib/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore에서 리뷰 목록을 가져오는 함수 (Stream을 반환하여 실시간 업데이트 가능)
Stream<QuerySnapshot> getReviewsStream(int movieId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('reviews')
      //  해당 영화 ID와 일치하는 리뷰만 필터링
      .where('movieId', isEqualTo: movieId)
      //  최신 리뷰가 먼저 보이도록 정렬
      .orderBy('createdAt', descending: true)
      .snapshots();
}
