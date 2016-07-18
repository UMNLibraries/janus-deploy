namespace :deploy do
  task :create_external_symlinks do
    on roles(fetch(:external_symlinks_roles)) do
      symlinks = fetch(:external_symlinks)
      symlinks.each do |symlink|
        execute 'ln', '-nfs', "#{release_path}/#{symlink[:source]}", symlink[:link]
      end
    end
  end
end
