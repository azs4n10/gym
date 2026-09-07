import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/profile.dart';
import '../theme/skin.dart';

class AppState extends ChangeNotifier {
  AppState(this._profile);

  UserProfile _profile;

  UserProfile get profile => _profile;
  Skin get skin => skinById(_profile.skinId);
  L get l => stringsFor(_profile.lang);
  Locale get locale => Locale(_profile.lang);

  static Future<AppState> create() async => AppState(await UserProfile.load());

  Future<void> update(UserProfile next) async {
    _profile = next;
    notifyListeners();
    await next.save();
  }

  Future<void> setSkin(String id) => update(_profile.copyWith(skinId: id));
  Future<void> setLang(String code) => update(_profile.copyWith(lang: code));
  Future<void> setFont(String id) => update(_profile.copyWith(font: id));
}

extension AppContext on BuildContext {
  L get l => watch<AppState>().l;
  Skin get skin => watch<AppState>().skin;
}
