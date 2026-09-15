import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Google Identity Services in the browser: loads Google's script once and
/// asks it for an access token for the given scopes. The token never leaves
/// the page except in requests to Google.
bool get available => true;

@JS('google.accounts.oauth2.initTokenClient')
external _TokenClient _initTokenClient(JSObject config);

extension type _TokenClient._(JSObject _) implements JSObject {
  external void requestAccessToken(JSObject overrides);
}

extension type _TokenResponse._(JSObject _) implements JSObject {
  @JS('access_token')
  external String? get accessToken;
  @JS('expires_in')
  external JSNumber? get expiresIn;
  external String? get error;
}

Future<void>? _loading;

Future<void> _loadScript() {
  return _loading ??= () {
    final done = Completer<void>();
    final s = web.HTMLScriptElement()
      ..src = 'https://accounts.google.com/gsi/client'
      ..async = true
      ..defer = true;
    s.onload = ((web.Event _) => done.complete()).toJS;
    s.onerror = ((web.Event _) => done.completeError(StateError('gsi script failed'))).toJS;
    web.document.head!.append(s);
    return done.future;
  }();
}

/// Returns the token and its lifetime in seconds, or null when Google did
/// not grant one. With [silent] set, no consent screen is shown; that works
/// once the user has consented before in this browser.
Future<(String, int)?> requestToken(String clientId, String scope, {bool silent = false}) async {
  try {
    await _loadScript();
  } catch (_) {
    return null;
  }
  final done = Completer<(String, int)?>();
  void finish((String, int)? v) {
    if (!done.isCompleted) done.complete(v);
  }

  final config = {
    'client_id': clientId,
    'scope': scope,
    'callback': (JSObject r) {
      final res = _TokenResponse._(r);
      final token = res.accessToken;
      if (token == null || (res.error ?? '').isNotEmpty) {
        finish(null);
      } else {
        finish((token, res.expiresIn?.toDartInt ?? 3600));
      }
    }.toJS,
    'error_callback': (JSObject _) => finish(null).toJS,
  }.jsify()! as JSObject;
  final client = _initTokenClient(config);
  client.requestAccessToken({'prompt': silent ? '' : 'consent'}.jsify()! as JSObject);
  // A closed popup never calls back; give up after a while.
  return done.future.timeout(const Duration(minutes: 3), onTimeout: () => null);
}
