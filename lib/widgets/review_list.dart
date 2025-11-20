// lib/widgets/review_list.dart (최종 삭제 기능 오류 해결)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/review_service.dart';

// ⭐️ [수정 1] StatelessWidget을 StatefulWidget으로 변경 ⭐️
class ReviewList extends StatefulWidget {
  final int movieId;

  const ReviewList({super.key, required this.movieId});

  @override
  State<ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  // ⭐️ [수정 2] 삭제 함수를 State 클래스 내부로 이동 ⭐️
  void _deleteReview(String reviewDocId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewDocId)
          .delete();

      // ⭐️ [추가] context 사용 전 mounted 체크 (경고 방지)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('리뷰가 삭제되었습니다.')));
      }
    } catch (e) {
      print('리뷰 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰 삭제에 실패했습니다. (권한 확인 필요)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ [수정 3] currentUserId는 build 메소드 내에서 선언 ⭐️
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: getReviewsStream(widget.movieId), // ⭐️ widget.movieId로 변경
      builder: (context, snapshot) {
        // 로딩, 에러, 데이터 없음 상태 처리
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('리뷰 로드 중 오류 발생: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('아직 등록된 리뷰가 없습니다.'));
        }

        final reviews = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final reviewDoc = reviews[index];
            final reviewData = reviewDoc.data() as Map<String, dynamic>;

            // ⭐️ 삭제 버튼 표시 여부 결정 ⭐️
            final isMyReview = reviewData['userId'] == currentUserId;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 평점 및 리뷰 텍스트 표시
                        Text(
                          '평점: ${reviewData['rating'].toStringAsFixed(1)} / 5점',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // ⭐️ 내가 쓴 리뷰일 경우에만 삭제 버튼 표시 ⭐️
                        if (isMyReview)
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red[400],
                            ),
                            // ⭐️ 삭제 함수 호출 시 문서 ID와 context 전달 ⭐️
                            onPressed: () =>
                                _deleteReview(reviewDoc.id, context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // 리뷰 텍스트
                    Text(
                      reviewData['reviewText'] ?? '리뷰 내용 없음',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    // 작성자 이메일
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          reviewData['userEmail'] ?? '익명',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
