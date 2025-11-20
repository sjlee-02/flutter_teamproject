// lib/widgets/review_form.dart (최종 별점 입력 활성화)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  //  초기 별점은 0점으로 설정하여, 사용자가 반드시 선택하게 유도
  double _currentRating = 0;
  bool _isLoading = false;

  //  Firestore 저장 핵심 로직
  void _submitReview() async {
    final reviewText = _reviewController.text.trim();

    if (reviewText.isEmpty || _currentRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('별점과 리뷰 내용을 입력해주세요.')));
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

      // Firestore 'reviews' 컬렉션에 데이터 저장
      await FirebaseFirestore.instance.collection('reviews').add({
        'movieId': widget.movieId,
        'movieTitle': widget.movieTitle,
        'userId': user.uid,
        'userEmail': user.email,
        'rating': _currentRating,
        'reviewText': _reviewController.text,
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

          // 별점 입력
          RatingBar.builder(
            initialRating: _currentRating,
            minRating: 0,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              //  별점 변경 시 _currentRating 값 업데이트 (setState 포함)
              setState(() {
                _currentRating = rating;
              });
            },
          ),
          const SizedBox(height: 20),

          // 리뷰 텍스트 입력
          TextField(
            controller: _reviewController,
            decoration: const InputDecoration(
              labelText: '솔직한 리뷰를 작성해주세요.',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 20),

          // 버튼
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
