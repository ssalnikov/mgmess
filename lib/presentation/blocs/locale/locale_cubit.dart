import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleState extends Equatable {
  final Locale? locale;

  const LocaleState({this.locale});

  @override
  List<Object?> get props => [locale];
}

class LocaleCubit extends Cubit<LocaleState> {
  static const _prefKey = 'app_locale';

  LocaleCubit() : super(const LocaleState()) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey);
    if (value != null) {
      emit(LocaleState(locale: Locale(value)));
    }
  }

  Future<void> setLocale(Locale? locale) async {
    emit(LocaleState(locale: locale));
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, locale.languageCode);
    }
  }
}
