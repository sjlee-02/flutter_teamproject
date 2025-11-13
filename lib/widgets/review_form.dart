// lib/widgets/review_form.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//  FlutterRatingBar 임포트는 그대로 유지합니다. (나중에 주석 해제 시 사용)
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewForm extends StatefulWidget {
  final int movieId;
  final String movieTitle;

  const ReviewForm({
    super.key,
    required this.movieId,
    required this.movieTitle,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _reviewController = TextEditingController();
  //  별점은 임시로 5점으로 고정합니다. (오류 방지를 위해 0이 아니어야 함)
  double _currentRating = 5.0;
  bool _isLoading = false;

  //  Firestore 저장 핵심 로직
  void _submitReview() async {
    final reviewText = _reviewController.text.trim();
    // 유효성 검사에서 별점 검사 로직은 잠시 제거합니다.
    if (reviewText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰 내용을 입력해주세요.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // 2. Firestore 'reviews' 컬렉션에 데이터 저장
      await FirebaseFirestore.instance.collection('reviews').add({
        'movieId': widget.movieId,
        'movieTitle': widget.movieTitle,
        'userId': user.uid,
        'userEmail': user.email,
        'rating': _currentRating,
        'reviewText': reviewText,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('리뷰가 성공적으로 등록되었습니다!')));
      }
    } catch (e) {
      print('리뷰 저장 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('리뷰 저장 중 오류가 발생했습니다.')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '"${widget.movieTitle}" 리뷰 작성',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          //  [수정] 별점 입력 (Rating Bar) - 오류 회피를 위해 주석 처리
          const Text('별점 입력 기능위치할 예정.', style: TextStyle(color: Colors.red)),
          /* FlutterRatingBar.builder(
            initialRating: _currentRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              _currentRating = rating;
            },
          ),
          */
          const SizedBox(height: 20),

          // 5. 리뷰 텍스트 입력
          TextField(
            controller: _reviewController,
            decoration: const InputDecoration(
              labelText: '리뷰를 작성해주세요.',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 20),

          // 6. 버튼
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submitReview,
                  child: const Text('리뷰 등록'),
                ),
        ],
      ),
    );
  }
}
