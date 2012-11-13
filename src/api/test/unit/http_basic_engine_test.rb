require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class HttpBasicEngineTest < ActiveSupport::TestCase
  def setup
    @configuration = {}
    @environment = {}
  end

  def test_returns_nil_when_no_configuration_or_environment_options_are_set
    auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_nil_when_read_only_hosts_do_not_match_environment_hosts
    @configuration['read_only_hosts'] = 'test_host'
    @environment['REMOTE_HOST'] = 'my_web_host'
    @environment['REMOTE_ADDR'] = '192.168.1.1'

    auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_authentication_cannot_be_completed
    auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)
    assert_equal 'Authentication required', auth_engine.authenticate.last
  end

  def test_returns_nil_if_the_user_agent_is_not_obs
    @configuration['read_only_hosts'] = 'test_host'
    @environment['REMOTE_HOST'] = 'test_host'
    auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)

    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_nobdy_user_when_the_user_agent_is_obs_webui
    user = User.find_by_login("_nobody_")

    @configuration['read_only_hosts'] = 'test_host'
    @configuration['allow_anonymous'] = true
    @environment['REMOTE_HOST'] = 'test_host'
    @environment['HTTP_USER_AGENT'] = 'obs-webui'
    @environment['REMOTE_HOST'] = 'test_host'

    auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)

    assert_equal user, auth_engine.authenticate
  end

  def test_returns_a_nobdy_user_when_the_user_agent_is_obs_software
    user = User.find_by_login("_nobody_")

    @configuration['read_only_hosts'] = 'test_host'
    @configuration['allow_anonymous'] = true
    @environment['REMOTE_HOST'] = 'test_host'
    @environment['HTTP_USER_AGENT'] = 'obs-software'
    @environment['REMOTE_HOST'] = 'test_host'

    auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)

    assert_equal user, auth_engine.authenticate
  end

  def test_returns_a_database_user_when_allow_anonymous_is_false
    @configuration['allow_anonymous'] = false

    user = User.create(:login => "Joe", :password => "MyPassword", :password_confirmation => "MyPassword", :email => "joe@example.com")
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"

    auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)

    assert_equal user, auth_engine.authenticate
  end

  def test_returns_a_nobody_user_when_allow_anonymous_is_true_but_there_is_a_database_user
    @configuration['allow_anonymous'] = true
    @configuration['read_only_hosts'] = 'test_host'
    @environment['REMOTE_HOST'] = 'test_host'
    @environment['HTTP_USER_AGENT'] = 'obs-software'
    @environment['REMOTE_HOST'] = 'test_host'

    user = User.create(:login => "Joe", :password => "MyPassword", :password_confirmation => "MyPassword", :email => "joe@example.com")
    nobody = User.find_by_login("_nobody_")
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"

    auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)

    assert_equal nobody, auth_engine.authenticate
  end

  def test_returns_a_database_user_when_allow_anonymous_is_not_test
     user = User.create(:login => "Joe", :password => "MyPassword", :password_confirmation => "MyPassword", :email => "joe@example.com")
     @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"

     auth_engine = Opensuse::Authentication::HttpBasicEngine.new(@configuration, @environment)

     assert_equal user, auth_engine.authenticate
  end
end