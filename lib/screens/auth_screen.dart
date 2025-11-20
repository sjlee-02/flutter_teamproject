// lib/screans/auth_screen.dart (최종 다크 디자인 및 자동로그인 제거)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String _userEmail = '';
  String _userPassword = '';
  bool _isLoading = false;

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    var userCredential;

    if (isValid) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        if (_isLogin) {
          // 로그인 로직
          userCredential = await _auth.signInWithEmailAndPassword(
            email: _userEmail,
            password: _userPassword,
          );
        } else {
          // 회원가입 로직
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: _userEmail,
            password: _userPassword,
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = '인증 오류가 발생했습니다. 다시 시도해 주세요.';
        if (e.message != null) {
          message = e.message!;
        }

        // 오류 발생 시 로딩 종료 및 스낵바 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print(e);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 앱 로고 및 타이틀
              const Text(
                '시네마 로그', // 앱 이름
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),

              // 폼 영역 시작
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 이메일 입력 필드
                    TextFormField(
                      key: const ValueKey('email'),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '이메일을 입력해주세요',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return '유효한 이메일 주소를 입력해 주세요.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _userEmail = value!;
                      },
                    ),

                    // 비밀번호 입력 필드
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const ValueKey('password'),
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '비밀번호를 입력해주세요',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return '비밀번호는 최소 6자 이상이어야 합니다.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _userPassword = value!;
                      },
                    ),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 정렬
                      children: [
                        // 회원가입 버튼
                        TextButton(
                          onPressed: () {
                            _toggleMode();
                          },
                          child: Text(
                            _isLogin ? '회원가입' : '로그인으로 돌아가기',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 로그인/회원가입 버튼
                    if (_isLoading)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _trySubmit,
                          child: Text(
                            _isLogin ? '로그인' : '회원가입',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                      ),

                    if (!_isLoading && !_isLogin) const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
