import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _enableEmail = false;
  bool _enableUsername = false;
  bool _enableGitLab = true;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _listenForDeepLinks();
    context.read<AuthBloc>().add(const AuthLoadConfig());
  }

  void _listenForDeepLinks() {
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == AppConfig.callbackScheme) {
        final token = uri.queryParameters['MMAUTHTOKEN'];
        final csrf = uri.queryParameters['MMCSRF'];
        if (token != null && token.isNotEmpty) {
          context.read<AuthBloc>().add(
                AuthOAuthCompleted(token: token, csrfToken: csrf),
              );
        }
      }
    });
  }

  Future<void> _launchOAuth() async {
    final url = Uri.parse(AppConfig.oauthUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              loginId: _loginController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPasswordLogin = _enableEmail || _enableUsername;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthConfigLoaded) {
            setState(() {
              _enableEmail = state.enableSignInWithEmail;
              _enableUsername = state.enableSignInWithUsername;
              _enableGitLab = state.enableSignUpWithGitLab;
              _configLoaded = true;
            });
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.chat,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MGMess',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mattermost for MyGames',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const CircularProgressIndicator();
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showPasswordLogin) ...[
                            _buildLoginForm(),
                            if (_enableGitLab) ...[
                              const SizedBox(height: 16),
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                          if (_enableGitLab)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _launchOAuth,
                                icon: const Icon(Icons.login),
                                label: const Text(
                                  'Sign in with GitLab',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          if (!_configLoaded && !showPasswordLogin && !_enableGitLab)
                            const CircularProgressIndicator(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    String hint;
    if (_enableEmail && _enableUsername) {
      hint = 'Email or Username';
    } else if (_enableEmail) {
      hint = 'Email';
    } else {
      hint = 'Username';
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _loginController,
            decoration: InputDecoration(
              labelText: hint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
            ),
            keyboardType: _enableEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your $hint';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
