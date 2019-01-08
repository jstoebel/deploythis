require 'deploythis/version'
require 'thor'

module Deploythis
  class CLI < Thor

    desc 'deploythis', 'deploy current branch'
    option :project_name, default: File.basename(Dir.getwd), aliases: :p
    option :branch, aliases: :b
    option :stage, default: :staging, aliases: :s, enum: ['staging', 'production']

    def deploythis
      puts command
      deploy_results = system command
      report_results deploy_results
    end

    default_task :deploythis

    private

    def command
      "#{branch_option} bundle exec cap #{options['stage']} deploy:clobber_npm deploy:clobber_lock deploy;"
    end

    def branch_option
      return if deploying_production?
      branch_name = options['branch'] || current_branch
      "BRANCH='#{branch_name}'"
    end

    def deploying_production?
      options[:stage] == 'production'
    end

    def current_branch
      branch_str = `git branch`
        .split("\n")
        .grep(/\*/)
        .first
      return if branch_str.nil?
      branch_str.gsub('* ', '')
    end

    def report_results(results)
      system("say '#{options['project_name']} deploy #{results ? 'complete' : 'failed'}'")
    end
  end

#   yeah, I have a shell function to get that info by dumping the staging db config as json
# it needs to be run on the server
# it requires a program called `jq` to filter JSON
# but you could modify it to just get the properties you want by editing the ruby code it runs instead
# ```function json-db-config() {
#   exec 3>&2
#   exec 2> /dev/null
#   local environment="${1:-staging}"
#   RAILS_ENV="$environment" /opt/ruby/bin/bundle exec rails runner 'puts Jade::Engine.configure_database.to_json' | jq ".${environment}"
#   exec 2>&3
# }```
# instead of converting that whole db config object to json, you could just grab the key for the environment you're looking for
# or install jq into your home folder on the server
# it's a small standalone CLI program
# This gives you the DB config object for an app, and the stuff in quotes at the end is Ruby, so you can manipulate it however you want
# `RAILS_ENV="$environment" /opt/ruby/bin/bundle exec rails runner 'puts Jade::Engine.configure_database'` (edited)
# This isn't good for production databases though, because the host property of that object will point to the master, and you always want to dump from the slave

# You can derive the slave hostname with sed: `db_host="$(echo $db_host | sed -re 's/^([^.]+)/\1-slave/')"`

# what about `ssh jstoebel@rails-stage-app-2 'cd /web/project/provisioneronline_staging/current && RAILS_ENV="staging" /opt/ruby/bin/bundle exec rails runner "puts Jade::Engine.configure_database.to_json"'`
end
