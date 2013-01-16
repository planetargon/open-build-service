require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class AuthenticationEngineTest < ActiveSupport::TestCase
  def setup
    @config = {}
    @environment = {}
  end

  def test_crowd_engine_set_to_on
    ApplicationSettings::AuthCrowdMode.set!(true)
    ApplicationSettings::AuthCrowdServer.set!('192.168.1.1')
    ApplicationSettings::AuthCrowdAppName.set!('obs-api')
    ApplicationSettings::AuthCrowdAppPassword.set!('password')

    @environment['Authorization'] = 'Joe'
    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CrowdEngine", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_on
    ApplicationSettings::AuthIchainMode.set!('on')

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::IchainEngine", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_simulate
    ApplicationSettings::AuthIchainMode.set!('simulate')
    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::IchainEngine", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_off
    ApplicationSettings::AuthIchainMode.set!('off')

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_nothing
    ApplicationSettings::AuthIchainMode.set!('')

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end

  def test_http_basic_engine_x_http_authorization_header
    ApplicationSettings::AuthAllowAnonymous.set!(true)

    @environment['X-HTTP-Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_http_basic_engine_authorization_header
    ApplicationSettings::AuthAllowAnonymous.set!(true)

    @environment['Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_http_basic_engine_http_authorization_header
    ApplicationSettings::AuthAllowAnonymous.set!(true)

    @environment['HTTP_AUTHORIZATION'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_http_basic_engine_http_non_anonymous
    ApplicationSettings::AuthAllowAnonymous.set!(false)

    @environment['HTTP_AUTHORIZATION'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_not_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_x_http_authorization_header_ldap_mode_on
    ApplicationSettings::AuthAllowAnonymous.set!(false)
    ApplicationSettings::LdapMode.set!(true)

    @environment['X-HTTP-Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s

  end

  def test_ldap_engine_authorization_header_ldap_mode_on
    ApplicationSettings::AuthAllowAnonymous.set!(false)
    ApplicationSettings::LdapMode.set!(true)

    @environment['Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_http_authorization_header_ldap_mode_on
    ApplicationSettings::AuthAllowAnonymous.set!(false)
    ApplicationSettings::LdapMode.set!(true)

    @environment['HTTP_AUTHORIZATION'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_ldap_mode_off
    ApplicationSettings::AuthAllowAnonymous.set!(false)
    ApplicationSettings::LdapMode.set!(false)

    @environment['HTTP_AUTHORIZATION'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_not_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_x_http_authorization_header
    @environment['X-HTTP-Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_authorization_header
    ApplicationSettings::AuthAllowAnonymous.set!(false)
    @environment['Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_x_http_authorization_header
    ApplicationSettings::AuthAllowAnonymous.set!(false)
    @environment['HTTP_AUTHORIZATION'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_no_engine
    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end
end