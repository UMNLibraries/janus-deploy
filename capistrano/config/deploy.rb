set :application, 'janus'
set :repo_url, 'git@github.com:UMNLibraries/janus-deploy.git'
set :branch, 'master'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Required in Capistrano 3 in order to sudo.
set :pty, true

set :deploy_user, 'swadm'

# Prevent 'scp: /tmp/git-ssh.sh: Permission denied' errors:
set :tmp_dir, "/home/#{fetch(:deploy_user)}/tmp"

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/swadm/var/www/deploy/#{fetch(:application)}"

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

# NodeJS path
set :nodejs_exe, '/swadm/bin/node'

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
    to: 'config/httpd/janus.conf',
    mode: '0644'
  },
  {
    from: 'templates/default.json.erb',
    to: 'config/default.json',
    mode: '0644'
  },
  {
    from: 'templates/janus-logrotate.ini.erb',
    to: 'config/janus-logrotate.ini',
    mode: '0644'
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
    source: "#{release_path}/config/httpd/janus.conf",
    link: '/swadm/etc/httpd/vhosts.d/stacks.d/janus.conf'
  }
])
set :external_symlinks_roles, [:web]

namespace :deploy do
  namespace :umnlib do
    # JME runs logrotate as root, so root must own configs in logrotate.d
    # To avoid difficulties with a root-owned, symlinked from release file,
    # it is copied to the actual logrotate location
    desc 'Set root ownership on logrotate conf'
    task :create_logrotate_conf do
      on roles(:app) do
        execute :sudo, "cp #{release_path}/config/janus-logrotate.ini /swadm/etc/logrotate.d/janus.ini"
        execute :sudo, "chown root:#{fetch(:deploy_user)} /swadm/etc/logrotate.d/janus.ini"
      end
    end

    desc 'Create application log directory'
    task :create_logdir do
      on roles(:app) do
        execute :mkdir, '-p', "#{shared_path}/log"
        execute :chmod, '2775', "#{shared_path}/log"
      end
    end

    desc 'Gracefully restart Apache'
    task :httpd_reload do
      on roles(:web), in: :sequence, wait: 5 do
        # Reload apache config (equivalent to graceful in prior distributions)
        execute :sudo, 'systemctl reload httpd'
      end
    end
  end
end

namespace :deploy do
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

before 'deploy:symlink:release', 'deploy:umnlib:create_logdir'
after  'deploy:symlink:release', 'deploy:umnlib:process_templates'
after  'deploy:umnlib:process_templates', 'deploy:umnlib:create_external_symlinks'
after  'deploy:umnlib:create_external_symlinks', 'deploy:umnlib:httpd_reload'
after  'deploy:umnlib:process_templates', 'deploy:umnlib:create_logrotate_conf'
