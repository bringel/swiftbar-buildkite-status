#!/usr/bin/env ruby
# frozen_string_literal: true

# <bitbar.title>BuildKite Status</bitbar.title>
# <bitbar.version>0.1</bitbar.version>
# <bitbar.author>Brad Ringel</bitbar.author>
# <bitbar.author.github>bringel</bitbar.author.github>
# <bitbar.desc>Show the status of your most recent BuildKite builds</bitbar.desc>
# <bitbar.dependencies>ruby</bitbar.dependencies>
# <swiftbar.environment>[ORG_NAME:'default_org', API_TOKEN:'default_token', BRANCHES:'develop,main', BUILD_COUNT:5]</swiftbar.environment>

require 'net/http'
require 'json'

class BuildKiteService
  def initialize(org_name:, api_token:)
    @hostname = 'api.buildkite.com'
    @org_name = org_name
    @api_token = api_token
  end

  def user
    @user ||= JSON.parse(Net::HTTP.get(URI::HTTPS.build(host: @hostname, path: '/v2/user'), request_headers))
  end

  def all_user_builds
    res = Net::HTTP.get_response(
      URI::HTTPS.build(
        host: @hostname,
        path: "/v2/organizations/#{@org_name}/builds/",
        query: "creator=#{user['id']}"
      ),
      request_headers
    )

    JSON.parse(res.body)
  end

  def branch_builds(branch:)
    query = if branch.is_a?(Array)
              "branch[]=#{branch.join('&branch[]=')}"
            else
              "branch=#{branch}"
            end

    res = Net::HTTP.get_response(
      URI::HTTPS.build(
        host: @hostname,
        path: "/v2/organizations/#{@org_name}/builds/",
        query: query
      ),
      request_headers
    )

    JSON.parse(res.body)
  end

  private

  def request_headers
    {
      Authorization: "Bearer #{@api_token}",
      Accept: 'application/json'
    }
  end
end

def parse_build(build)
  build_data = build.slice('id', 'web_url', 'url', 'number', 'state', 'message', 'branch', 'created_at', 'finished_at')

  status_icon_lookup = {
    'scheduled' => 'clock.fill',
    'running' => 'arrow.triangle.2.circlepath',
    'passed' => 'checkmark.circle.fill',
    'failed' => 'xmark.octogon.fill',
    'cancelled' => 'minus.circle.fill',
    'skipped' => 'forward.end.alt'
  }

  status_color_lookup = {
    'scheduled' => '#000000,#ffffff',
    'running' => '#0969da',
    'passed' => '#1a7f37',
    'failed' => '#cf222e',
    'cancelled' => '#bf8700',
    'skipped' => '#000000,#ffffff'
  }

  build_data.merge(
    'status_icon' => status_icon_lookup[build_data['state']],
    'status_color' => status_color_lookup[build_data['state']]
  )
end

def to_header_string(build)
  [
    build['message'][0, 30],
    '|',
    "sfimage=#{build['status_icon']}",
    "sfcolor=#{build['status_color']}",
  ].join(' ')
end

def to_menu_string(build)
  [
    build['message'],
    '|',
    "sfimage=#{build['status_icon']}",
    "sfcolor=#{build['status_color']}",
    "href=#{build['web_url']}"
  ].join(' ')
end

class EnvironmentError < StandardError; end

if ENV['ORG_NAME'] == 'default_org' || ENV['API_TOKEN'] == 'default_token'
  raise(EnvironmentError, 'You need to update your environment values')
end

service = BuildKiteService.new(org_name: ENV['ORG_NAME'], api_token: ENV['API_TOKEN'])

my_builds = service.all_user_builds.map { |b| parse_build(b) }
branches = ENV['BRANCHES'].split(',')
branch_builds = service.branch_builds(branch: branches.length > 1 ? branches : branches.first)
                       .map { |b| parse_build(b) }
                       .group_by { |b| b['branch'] }

puts to_header_string(my_builds.first)
puts '---'
my_builds[0, ENV['BUILD_COUNT']].each { |b| puts(to_menu_string(b)) }
puts '---'
branch_builds.each do |(branch_name, builds)|
  puts branch_name
  builds[0, ENV['BUILD_COUNT']].each do |b|
    puts "-- #{to_menu_string(b)}"
  end
end
