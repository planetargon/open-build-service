ENV["RAILS_ENV"] = "test"
require 'simplecov'
require 'simplecov-rcov'
SimpleCov.start 'rails' if ENV["DO_COVERAGE"]

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/unit'
require 'mocha'

# uncomment to enable tests which currently are known to fail, but where either the test
# or the code has to be fixed
#$ENABLE_BROKEN_TEST=true

    def inject_build_job( project, package, repo, arch )
      job=IO.popen("find #{Rails.root}/tmp/backend_data/jobs/#{arch}/ -name #{project}::#{repo}::#{package}-*")
      jobfile=job.readlines.first
      return unless jobfile
      jobfile.chomp!
      jobid=""
      IO.popen("md5sum #{jobfile}|cut -d' ' -f 1") do |io|
         jobid = io.readlines.first.chomp
      end
      data = REXML::Document.new(File.new(jobfile))
      verifymd5 = data.elements["/buildinfo/verifymd5"].text
      f = File.open("#{jobfile}:status", 'w')
      f.write( "<jobstatus code=\"building\"> <jobid>#{jobid}</jobid> <workerid>simulated</workerid> <hostarch>#{arch}</hostarch> </jobstatus>" )
      f.close
      system("cd #{Rails.root}/test/fixtures/backend/binary/; exec find . -name '*#{arch}.rpm' -o -name '*src.rpm' -o -name logfile | cpio -H newc -o 2>/dev/null | curl -s -X POST -T - 'http://localhost:3201/putjob?arch=#{arch}&code=success&job=#{jobfile.gsub(/.*\//, '')}&jobid=#{jobid}' > /dev/null")
      system("echo \"#{verifymd5}  #{package}\" > #{jobfile}:dir/meta")
    end

module ActionController
  module Integration #:nodoc:
    class Session
      def add_auth(headers)
        headers = Hash.new if headers.nil?
        if !headers.has_key? "HTTP_AUTHORIZATION" and IntegrationTest.basic_auth
          headers["HTTP_AUTHORIZATION"] = IntegrationTest.basic_auth
        end
        return headers
      end

      alias_method :real_process, :process
      def process(method, path, parameters, rack_env)
        CONFIG['global_write_through'] = true
        self.accept = "text/xml,application/xml"
        real_process(method, path, parameters, add_auth(rack_env))
      end

      def get_html(path, parameters = nil, rack_env = nil)
        self.accept = "text/html";
        real_process(:get, path, parameters, add_auth(rack_env))
      end

      def raw_post(path, data, parameters = nil, rack_env = nil)
        rack_env ||= Hash.new
        rack_env['CONTENT_TYPE'] = 'application/octet-stream'
        rack_env['CONTENT_LENGTH'] = data.length
        rack_env['RAW_POST_DATA'] = data
        process(:post, path, parameters, add_auth(rack_env))
      end

      def raw_put(path, data, parameters = nil, rack_env = nil)
        rack_env ||= Hash.new
        rack_env['CONTENT_TYPE'] = 'application/octet-stream'
        rack_env['CONTENT_LENGTH'] = data.length
        rack_env['RAW_POST_DATA'] = data
        process(:put, path, parameters, add_auth(rack_env))
      end

    end
  end

  class IntegrationTest

    def teardown
      Rails.cache.clear
    end
    
    @@auth = nil

    def reset_auth
      @@auth = nil
    end

    def self.basic_auth
      return @@auth
    end

    def basic_auth
      return @@auth
    end

    def prepare_request_with_user( user, passwd )
      re = 'Basic ' + Base64.encode64( user + ':' + passwd )
      @@auth = re
    end
  
    # will provide a user without special permissions
    def prepare_request_valid_user 
      prepare_request_with_user 'tom', 'thunder'
    end
  
    def prepare_request_invalid_user
      prepare_request_with_user 'tom123', 'thunder123'
    end

    def load_backend_file(path)
      File.open(ActionController::TestCase.fixture_path + "/backend/#{path}").read()
    end

    def assert_xml_tag(conds)
      node = ActiveXML::Node.new(@response.body)
      ret = node.find_matching(NodeMatcher::Conditions.new(conds))
      raise MiniTest::Assertion.new("expected tag, but no tag found matching #{conds.inspect} in:\n#{node.dump_xml}") unless ret
    end

    def assert_no_xml_tag(conds)
     node = ActiveXML::Node.new(@response.body)
     ret = node.find_matching(NodeMatcher::Conditions.new(conds))
     raise MiniTest::Assertion.new("expected no tag, but found tag matching #{conds.inspect} in:\n#{node.dump_xml}") if ret
    end

    # useful to fix our test cases
    def url_for(hash)
      raise ArgumentError.new("we need a hash here") unless hash.kind_of? Hash
      raise ArgumentError.new("we need a :controller") unless hash.has_key?(:controller)
      raise ArgumentError.new("we need a :action") unless hash.has_key?(:action)
      super(hash)
    end

    def wait_for_publisher
      Rails.logger.debug "Wait for publisher"
      counter = 0
      while counter < 100
        events = Dir.open(Rails.root.join("tmp/backend_data/events/publish"))
        #  3 => ".", ".." and ".ping"
        break unless events.count > 3
        sleep 0.5
        counter = counter + 1
      end
      if counter == 100
        raise "Waited 50 seconds for publisher"
      end
    end

    def wait_for_scheduler_start
      # make sure it's actually tried to start
      Suse::Backend.start_test_backend
      Rails.logger.debug "Wait for scheduler thread to finish start"
      counter = 0
      marker = Rails.root.join("tmp", "scheduler.done")
      while counter < 100
        return if File.exists?(marker)
        sleep 0.5
        counter = counter + 1
      end
    end

    def run_scheduler( arch )
      Rails.logger.debug "RUN_SCHEDULER #{arch}"
      perlopts="-I#{Rails.root}/../backend -I#{Rails.root}/../backend/build"
      IO.popen("cd #{Rails.root}/tmp/backend_config; exec perl #{perlopts} ./bs_sched --testmode #{arch}") do |io|
         # just for waiting until scheduler finishes
         io.each {|line| line.strip.chomp unless line.blank? }
      end
    end

  end 
end

class ActiveSupport::TestCase
  def assert_xml_tag(data, conds)
    node = ActiveXML::Node.new(data)
    ret = node.find_matching(NodeMatcher::Conditions.new(conds))
    assert ret, "expected tag, but no tag found matching #{conds.inspect} in:\n#{node.dump_xml}" unless ret
  end

  def assert_no_xml_tag(data, conds)
    node = ActiveXML::Node.new(data)
    ret = node.find_matching(NodeMatcher::Conditions.new(conds))
    assert !ret, "expected no tag, but found tag matching #{conds.inspect} in:\n#{node.dump_xml}" if ret
  end

  def load_backend_file(path)
    File.open(ActionController::TestCase.fixture_path + "/backend/#{path}").read()
  end

  def teardown
    Rails.cache.clear
  end
end

