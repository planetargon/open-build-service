require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class LdapEngineTest < ActiveSupport::TestCase
  def setup
    @configuration = {}
    @environment = {}
  end

  def test_returns_nil_when_no_authorization_is_set
    auth_engine = Opensuse::Authentication::LdapEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_no_authorization_is_set
    auth_engine = Opensuse::Authentication::LdapEngine.new(@configuration, @environment)
    assert_equal 'Authentication required', auth_engine.authenticate.last
  end

  def test_returns_nil_when_a_user_cannot_be_found
    User.any_instance.stubs(:find_with_ldap).returns([])
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::LdapEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_nil_when_no_password_is_provided
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:')}"
    auth_engine = Opensuse::Authentication::LdapEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_no_password_is_provided
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:')}"
    auth_engine = Opensuse::Authentication::LdapEngine.new(@configuration, @environment)

    user, message = auth_engine.authenticate

    assert_equal "User '#{auth_engine.user_login}' did not provide a password", message
  end

  def test_returns_a_user_when_ldap_info_is_found
    User.expects(:find_with_ldap).returns(['joe2@example.com'])
    user = User.create(:login => "Joe", :password => "MyPassword", :password_confirmation => "MyPassword", :email => "joe@example.com")
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::LdapEngine.new(@configuration, @environment)
    assert_equal user, auth_engine.authenticate
  end

  def test_updates_a_users_email_address_when_ldap_info_is_found
    User.expects(:find_with_ldap).returns(['joe2@example.com'])
    user = User.create(:login => "Joe", :password => "MyPassword", :password_confirmation => "MyPassword", :email => "joe@example.com")
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::LdapEngine.new(@configuration, @environment)
    authenticated_user = auth_engine.authenticate
    assert_equal authenticated_user, user
    assert_equal 'joe2@example.com', authenticated_user.email
  end
end