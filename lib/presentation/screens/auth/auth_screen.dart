import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/di/session_manager.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/url_utils.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/server/server_list_cubit.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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
    context.read<AuthBloc>().add(const AuthLoadConfig());
  }

  Future<void> _launchOAuth() async {
    // Record which account is authenticating so the OAuth callback
    // (handled in App) routes tokens to the correct session.
    sl<SessionManager>().startOAuth(currentSession.accountId);
    final url = Uri.parse(currentSession.oauthUrl);
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
                  Text(
                    context.l10n.mattermostForMyGames,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push(RouteNames.addServer),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentSession.serverUrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  _buildServerSwitcher(),
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
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      context.l10n.or,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
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
                                label: Text(
                                  context.l10n.signInWithGitLab,
                                  style: const TextStyle(fontSize: 16),
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

  Widget _buildServerSwitcher() {
    return BlocBuilder<ServerListCubit, ServerListState>(
      builder: (context, state) {
        final currentAccountId = currentSession.accountId;
        final otherAccounts = state.accounts
            .where((a) => a.id != currentAccountId)
            .toList();
        if (otherAccounts.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.servers,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...otherAccounts.map((account) {
                final host = UrlUtils.extractHost(account.serverUrl);
                final name = account.displayName.isNotEmpty
                    ? account.displayName
                    : host;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.accent,
                      radius: 12,
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(name),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context
                          .read<ServerListCubit>()
                          .switchServer(account.id);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginForm() {
    String hint;
    if (_enableEmail && _enableUsername) {
      hint = context.l10n.emailOrUsername;
    } else if (_enableEmail) {
      hint = context.l10n.email;
    } else {
      hint = context.l10n.username;
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
                return context.l10n.pleaseEnterField(hint);
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: context.l10n.password,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.l10n.pleaseEnterPassword;
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
              child: Text(
                context.l10n.signIn,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
