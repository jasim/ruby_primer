#! /usr/bin/env ruby

require "rubygems"
require "bundler/setup"

$LOAD_PATH << File.dirname(__FILE__) + "/../lib"
require 'rubymonk_model'
require 'rubymonk_client'
require 'rubymonk_client_config'

require 'fssm'
require 'uuid'

CONFIG = RubymonkClientConfig.new(".rubymonk_open").get
SANDBOX_URL = CONFIG["sandbox_server"]
SANDBOX_TOKEN = CONFIG["sandbox_token"]

CLIENT = RubymonkClient.new(SANDBOX_URL+ "/import/create", SANDBOX_TOKEN)

UPDATE_FREQUENCY_SECONDS = 5
DOCS = File.join(File.dirname(__FILE__), '..', "docs")

puts ""
puts "!!!! READ THIS !!!!"
puts "Visit #{SANDBOX_URL}/?sandbox_token=#{SANDBOX_TOKEN} to see the content.\n\n"

def monitor
  FSSM.monitor(DOCS, '**/*', :directories => true) do
    update { timed_republish }
    delete { timed_republish }
    create { timed_republish }
  end
end

def republish
  content_hash = RubymonkModel.new(DOCS).build_hash.merge({ "sandbox_token" => SANDBOX_TOKEN})
  begin
    response = CLIENT.sync_data(content_hash)
    puts Time.now
    if response.ok?
      puts "Success."
    elsif response.bad_request?
      puts "Changes not uploaded. Server returned error:"
      puts response.body
    else
      puts "Changes not uploaded. Server returned an error."
    end
  rescue Errno::ECONNREFUSED
    puts "Could not connect to server."
  end
end

def timed_republish
  sleep UPDATE_FREQUENCY_SECONDS
  republish
end

republish
monitor
