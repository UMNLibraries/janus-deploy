namespace :deploy do
  task :process_templates do
    on roles(fetch(:templates_roles)) do
      templates = fetch(:templates)
      templates.each do |template|
        # The template processing happens locally, so the from_path must NOT be
        # prepended with the release_path.
        from_path = template[:from]
        to_path = "#{release_path}/#{template[:to]}"
        from_result = StringIO.new(ERB.new(File.read(from_path)).result(binding))
        upload! from_result, to_path
        info "copying: #{from_path} to: #{to_path}"
      end
    end
  end
end
