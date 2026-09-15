{{flutter_js}}
{{flutter_build_config}}

// Mount into a host element so the CSS safe-area insets in index.html keep the
// UI clear of the notch and the rounded display corners; Flutter web does not
// report those insets to MediaQuery.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: { hostElement: document.querySelector('#gym-app') },
});
