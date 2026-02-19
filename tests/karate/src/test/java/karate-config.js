function fn() {
  // Determine environment — pass via -Dkarate.env=dev|staging|prod
  var env = karate.env || 'dev';
  karate.log('karate.env =', env);

  // Base config
  var config = {
    env: env,
    baseUrl: 'http://localhost:8080/api/v1',
    googleAuthClientId: java.lang.System.getenv('GOOGLE_AUTH_CLIENT_ID') || '',
    adminEmail: 'admin@aim.edu',
    adminPassword: 'admin123',
    authToken: '',
    adminToken: ''
  };

  // Per-environment overrides
  if (env === 'dev') {
    config.baseUrl = 'http://localhost:8080/api/v1';
  } else if (env === 'staging') {
    config.baseUrl = 'https://makeitexist-staging.onrender.com/api/v1';
  } else if (env === 'prod') {
    config.baseUrl = 'https://makeitexist.onrender.com/api/v1';
  }

  // Global request headers
  karate.configure('headers', { 'Content-Type': 'application/json' });

  // Connection / read timeouts (ms)
  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 30000);

  // If SSL issues, disable strict verification (not for prod)
  if (env !== 'prod') {
    karate.configure('ssl', true);
  }

  return config;
}
