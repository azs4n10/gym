{{flutter_js}}
{{flutter_build_config}}

// The deploy script stamps the version below; a plain `flutter run` leaves the
// placeholder, and then no worker is registered, so development always loads
// fresh files.
(function () {
  var version = '__SW_VERSION__';
  if (version.indexOf('__') === 0 || !('serviceWorker' in navigator)) return;
  var hadController = !!navigator.serviceWorker.controller;
  var painted = false;
  window.addEventListener('flutter-first-frame', function () { painted = true; });
  // A newer worker took over while the boot screen was still up: start again
  // on its files rather than finishing the launch on the old ones.
  navigator.serviceWorker.addEventListener('controllerchange', function () {
    if (hadController && !painted) location.reload();
  });
  navigator.serviceWorker
    .register('sw.js?v=' + version, { updateViaCache: 'none' })
    .catch(function (e) { console.warn('Service worker not registered:', e); });
})();

// Mount into a host element so the CSS safe-area insets in index.html keep the
// UI clear of the notch and the rounded display corners; Flutter web does not
// report those insets to MediaQuery.
_flutter.loader.load({
  config: { hostElement: document.querySelector('#gym-app') },
});
