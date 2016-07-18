# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'janus'
set :repo_url, 'git@github.com:UMNLibraries/janus.git'
set :branch, 'master'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Required in Capistrano 3 in order to sudo.
set :pty, true

set :deploy_user, 'swadm'

# Prevent 'scp: /tmp/git-ssh.sh: Permission denied' errors:
set :tmp_dir, "/home/#{fetch(:deploy_user)}/tmp"

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/swadm/deploy/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# TODO: Not sure we need this anymore!
#set :default_env, { path: '/swadm/bin:/swadm/usr/bin:$PATH' }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :anyenv_root, '/swadm/anyenv/envs'

# Here we use lambdas to pull in stage-specific variables. See: http://capistranorb.com/documentation/faq/how-can-i-access-stage-configuration-variables/
set :nodejs_exe, -> { "#{fetch(:anyenv_root)}/ndenv/versions/#{fetch(:nodejs_version)}/bin/node" }
set :rbenv_ruby, -> { fetch(:ruby_version) }

# Anyenv places rbenv into /swadm/anyenv/envs/rbenv
set :rbenv_custom_path, "#{fetch(:anyenv_root)}/rbenv"

# Default is :app, but we need to ensure that we restart
# passenger on all instances of apache, and we use the :web
# role for that. HOWEVER: The old restart mechanism touches
# release_path/tmp/restart.txt. Will that even work to restart
# all instances of passenger on all machines?!
set :passenger_roles, :web

# For capistrano-npm:
set :npm_roles, :app

set :nodejs_host, 'localhost'
set :nodejs_port, 1337

# from: template files
# to: template processing output files
# All are children of release_path.
set(:templates, [
  {
    from: 'templates/janus.conf.erb',
    to: 'config/httpd/janus.conf'
  },
  {
    from: 'templates/default.json.erb',
    to: 'config/default.json'
  },
])
set :templates_roles, [:app]

# children of release_path
set(:entry_points, %w(
  app.js public
))

# source: children of release_path
# link: absolute paths
set(:external_symlinks, [
  {
    source: 'config/httpd/janus.conf',
    link: '/swadm/etc/httpd/conf.d/stacks.d/janus.conf'
  },
])
set :external_symlinks_roles, [:web]

namespace :deploy do

  after 'deploy:symlink:release', 'deploy:process_templates'
  after 'deploy:process_templates', 'deploy:create_external_symlinks'

  desc 'Gracefully restart Apache'
  # Previously this was httpd_reload, but Aapche actually can't reload its config
  # without restarting: https://blogs.oracle.com/oswald/entry/urban_legends_apache_reload_ed
  task :httpd_graceful do
    on roles(:web), in: :sequence, wait: 5 do
      # Note: A command executed via sudo must match exactly what is in the
      # sudoers file, or the user will be prompted for a password.
      execute :sudo, '/sbin/service httpd graceful'
    end
  end

  after 'deploy:create_external_symlinks', :httpd_graceful

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
