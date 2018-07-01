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
end
