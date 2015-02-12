require 'al-test-utils'
require 'pry'

class TestUseradd < Test::Unit::TestCase
  include AlTestUtils

  def setup
    super
    @command = File.join(@examples_dir, "useradd")
    make_ou("People")
    @user_class.prefix = "ou=People"

    # hack just to see if we can get a failing test for the right reason
    @inet_user_class = Class.new( ActiveLdap::Base)
    @inet_user_class_classes = ["inetOrgPerson"]
    @inet_user_class.ldap_mapping( :dn_attribute => :uid,
                                   :prefix => "ou=People",
                                   :scope => :sub,
                                   :classes => @inet_user_class_classes )
    assign_class_name( @inet_user_class, "InetUser" )
  
  end

  priority :must

  priority :normal
  def test_exist_user
    make_temporary_user do |user, password|
      assert(@user_class.exists?(user.uid))
      assert_equal([false, "User #{user.uid} already exists.\n"],
                   run_command(user.uid, user.cn, user.uid_number))
      assert(@user_class.exists?(user.uid))
    end
  end

  def test_add_user
    ensure_delete_user("test-user") do |uid,|
      assert_useradd_successfully(uid, uid, 10000)
    end
  end

  def test_add_inet_user_simple_dn
    ensure_delete_user("test-user") do |uid,|
      assert_useradd_inet_user_successfully(uid, uid, uid)
    end
  end

  def test_add_inet_user_dn_with_plus
    ensure_delete_user("test+buser") do |uid,|
      assert_useradd_inet_user_successfully(uid, uid, uid)
    end
  end

  private
    
  def assert_useradd_inet_user_successfully(name, cn, uid, *args, &block)
    _wrap_assertion do
      assert(!@inet_user_class.exists?(name))
      args.concat([name, cn, uid])
      ex_command = @command
      begin
        @command = "/Users/r604544/work/activeldap/examples/userinetadd"
        assert_equal([true, ""], run_command(*args, &block))
        assert(@inet_user_class.exists?(name))

        user = @inet_user_class.find(name)
        assert_equal(name, user.uid)
        assert_equal(cn, user.cn)
      ensure
        @command = ex_command
      end
    end
  end
  
  def assert_useradd_successfully(name, cn, uid, *args, &block)
    _wrap_assertion do
      assert(!@user_class.exists?(name))
      args.concat([name, cn, uid])
      assert_equal([true, ""], run_command(*args, &block))
      assert(@user_class.exists?(name))

      user = @user_class.find(name)
      assert_equal(name, user.uid)
      assert_equal(cn, user.cn)
      assert_equal(uid.to_i, user.uid_number)
      assert_equal(uid.to_i, user.gid_number)
      assert_equal(uid.to_s, user.uid_number_before_type_cast)
      assert_equal(uid.to_s, user.gid_number_before_type_cast)
    end
  end

  def assert_useradd_failed(name, cn, uid, message, *args, &block)
    _wrap_assertion do
      assert(!@user_class.exists?(name))
      args.concat([name, cn, uid])
      assert_equal([false, message], run_command(*args, &block))
      assert(!@user_class.exists?(name))
    end
  end
end
