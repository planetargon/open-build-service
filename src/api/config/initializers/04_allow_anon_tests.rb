if Rails.env.test?
  CONFIG['allow_anonymous'] = true
  # ApplicationSettings::AuthAllowAnonymous.set!(true)
  # ApplicationSettings::AuthReadOnlyHosts.set!(['127.0.0.1', '::1'])
end
