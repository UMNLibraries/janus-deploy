# janus-deploy

Deploys the [Janus](https://github.com/UMNLibraries/janus) web application, with [UMN plugins](https://github.com/UMNLibraries/janus-uri-factory-plugins), for UMN Libraries.

## Setup

We use the Ruby-based [Capistrano 3](http://capistranorb.com/) to deploy Janus to remote machines, with [Bundler](http://bundler.io/) to install some Capistrano plugins.

### Set Up Remote Machines

We use [Anisble](http://www.ansible.com/) to set up remote machines for deployment via Capistrano. See the [orbis-ansible](https://github.umn.edu/Libraries/orbis-ansible) repo for details of how we set up the `stacks*.lib.umn.edu` environments on the orbis machines, especially if your remote machine is not set up yet.

### Install Local Machine Dependencies

If you have not deployed Janus before, first install Bundler on your local machine, then do this:

```
git clone git@github.com:UMNLibraries/janus-deploy.git
cd janus-deploy/capistrano/
bundle install --path vendor/bundle
```

Capistrano comes with executables. Use Bundler to ensure those executables will use only the gems in the bundle you just installed, and not any versions of those same gems that may be installed elsewhere. There are two ways to do this. We recommend this...

```
bundle install --binstubs
```

...which will install bundler-wrapped executables in `janus-deploy/capistrano/bin`. The rest of these docs will assume the use of this method.

The other way is to prepend each executable call with `bundle exec`. See the "Executables" section of [Gem Versioning and Bundler: Doing it Right](http://yehudakatz.com/2011/05/30/gem-versioning-and-bundler-doing-it-right/) for more details.

## Deployment

Now you should be able to deploy Janus to the `dev`, `stage`, and `prod` environments. For example:

```
cd janus-deploy/capistrano
bin/cap dev deploy
```
