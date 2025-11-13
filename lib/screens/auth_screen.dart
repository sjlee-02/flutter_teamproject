// lib/screans/auth_screen.dart (최종 인증 로직 포함 버전)

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
          userCredential = await _auth.signInWithEmailAndPassword(
            email: _userEmail,
            password: _userPassword,
          );
        } else {
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
      appBar: AppBar(title: Text(_isLogin ? '로그인' : '회원가입')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('email'),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: '이메일 주소'),
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
                TextFormField(
                  key: const ValueKey('password'),
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '비밀번호'),
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

                const SizedBox(height: 20),

                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _trySubmit,
                    child: Text(_isLogin ? '로그인' : '회원가입'),
                  ),

                if (!_isLoading)
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
