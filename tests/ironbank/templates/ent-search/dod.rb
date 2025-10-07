# frozen_string_literal: true
#
# DodContainer creates a container we can submit to the DoD bank.
#
# When called, the `build_container` method will:
#
# - generate the container and its files
# - download all files declared in `hardening_manifest.yaml`
# - build the docker image
# - create a tarball with the docker container
#
# The class uses **public** snapshots, and will download it
# from our oublic URLs by browsing `artifacts-api.elastic.co`
#
# Generating a DoD container that we can submit still requires
# some manual steps: we need to tweak the `hardening_manifest.yaml`
# file to point to the target release, and copy over the files to the
# DoD gitlab.
require 'erb'
require 'date'
require 'fileutils'
require 'down'
require 'digest'
require 'yaml'
require 'retriable'

module Dist::Packaging
  class ChecksumException < StandardError
  end

  # Represents a hardening_manifest.yaml and downloads its resources
  class Manifest
    attr_reader :path

    def initialize(path)
      @path = path
      @data = YAML.load_file(path)
    end

    def log(msg)
      puts "[manifest] #{msg}"
    end

    def checksum(filename, type)
      digest =
        case type
        when 'md5'
          Digest::MD5
        when 'sha1'
          Digest::SHA1
        when 'sha256'
          Digest::SHA256
        else
          Digest::SHA512
        end

      check = digest.file(filename)
      check.hexdigest
    end

    def get_digest(url)
      log("Downloading digest from #{url}")
      Retriable.retriable do
        remote_digest = Down.open(url, headers: { 'Cache-Control' => 'max-age=0' })
        begin
          digest = remote_digest.read
        ensure
          remote_digest.close
        end
        res = digest.strip.split[0]
        log("Digest is #{res}")
        res
      end
    end

    def download_binaries(destination_dir)
      unless File.directory?(destination_dir)
        FileUtils.mkdir_p(destination_dir)
      end
      downloaded = []
      @data['resources'].each do |resource|
        log("Looking at #{resource['filename']}")
        destination = destination_dir.join(resource['filename']).to_s

        if resource['validation']
          validation_type = resource['validation']['type']
          static_digest = resource['validation'].key?('value')

          # we get the digest from the `value` field *or* from an URL
          public_digest = if static_digest
            resource['validation']['value'].strip
          else
            get_digest(resource['validation']['url'])
          end

          # If a file exists, we check if it's the published snapshot or a local build.
          # If it's different, we remove it and download it.
          if File.exist?(destination)
            log("We already have #{destination} on disk  Checking it..")
            digest = checksum(destination, validation_type)
            if digest == public_digest
              log('The digest matches we can reuse it')
            else
              log("The digest does not match '#{digest}' != '#{public_digest}', deleting it for a new download")
              File.delete(destination)
            end
          end
        else
          log('No checksum')
          # if we don't have a digest we always delete
          File.delete(destination) if File.exist?(destination)
          public_digest = nil
        end

        Retriable.retriable(tries: 3, base_interval: 120) do
          unless File.exist?(destination)
            log("Downloading #{resource['url']} to #{destination}")
            Down.download(resource['url'], destination: destination, headers: { 'Cache-Control' => 'max-age=0' })
            public_digest = get_digest(resource['validation']['url']) unless static_digest
          end

          if public_digest
            log("[manifest] Verifying checksum for #{destination}")
            digest = checksum(destination, validation_type)
            if digest != public_digest
              log('Digest does not match - trying to ensure we have the latest...')
              public_digest = get_digest(resource['validation']['url']) unless static_digest
              if digest != public_digest
                log('Digest still does not match - refetching the artifact...')
                log("Deleting #{destination} for new attempts")
                File.delete(destination) # this will allow a retry
                raise ChecksumException.new("Checksum did not match '#{digest}' != '#{public_digest}'")
              end
            end
          end
        end

        downloaded.append(destination)
      end
      downloaded
    end
  end

  # Generates a Docker container for the DoD and builds it.
  class DodContainer < Docker

    attr_reader :release_tarball, :snapshot_url, :snapshot_tarball, :snapshot_sha, :include_libjemalloc2

    def initialize(build_environment = :centos8)
      @name = 'dod'
      Base.instance_method(:initialize).bind(self).call('enterprise-search', build_environment)

      case build_environment
      when :ubi9
        @base_image = 'ubi9/ubi'
        @base_tag = '9.6'
      end

      @image_environment = '-dod'
      @docker_jdk = DOCKER_JDK_VERSION
      @tini_bin = TINI_DEFAULT_BIN
      @build_id = rand(36**16).to_s(36)
      @image_suffix = ''
      @package_manager = 'yum'
      @release_tarball = ''
      @snapshot_url = ''
      @snapshot_tarball = ''
      @snapshot_sha = ''
      @cached_product_version = ''
      @process_manifest = true
      @is_ironbank_release = ENV.has_key?('IRONBANK_RELEASE') && ENV['IRONBANK_RELEASE'] == 'true'
      @include_libjemalloc2 = @is_ironbank_release ? '' : 'libjemalloc2 '
      @manifest_downloads = []
    end

    def release_dockerfile
      release_dir.join('Dockerfile')
    end

    def product_version
      return @cached_product_version if @cached_product_version != ''
      @cached_product_version =
        if ENV.has_key?('PRODUCT_MAJOR_VERSION')
          get_latest_public_version(ENV['PRODUCT_MAJOR_VERSION'])
        else
          super
        end
      @cached_product_version
    end

    def version
      product_version
    end

    def minor_version
      minor_product_version
    end

    def elasticsearch_download_url
      "https://www.elastic.co/downloads/past-releases/elasticsearch-#{product_version.tr('.', '-')}"
    end

    def top_release_dir
      PROJECT_ROOT.join('release')
    end

    def release_dir
      PROJECT_ROOT.join('release', @name)
    end

    def tag
      "docker.elastic.co/enterprise-search/enterprise-search-#{@name}:#{product_version}-SNAPSHOT"
    end

    def build_args
      puts "Using BUILD_ID: #{@build_id}"
      ['--build-arg', "BUILD_ID=#{@build_id}",
       '--build-arg', 'BASE_REGISTRY=registry.access.redhat.com',
       '--build-arg', "BASE_IMAGE=#{@base_image}",
       '--build-arg', "BASE_TAG=#{@base_tag}",
       '--no-cache']
    end

    def build_container(save = true)
      source_dir = shared_dist_dir.join(@name)
      FileUtils.mkdir_p(source_dir)

      # first step, we copy README.md.erb from the root dist/shared dir
      readme = shared_dist_dir.join('README.md.erb')
      cp(readme, source_dir.join('README.md.erb'))

      build_id = rand(36**16).to_s(36)
      puts 'Building a DoD docker image from latest public snapshot.'
      puts "Using BUILD_ID: #{build_id}"

      # Get the release info and download the tarball if not provided
      retrieve_elastic_artifacts_release_info if @release_tarball == ''

      unless @is_ironbank_release
        # we copy the tarball
        cp(release_tarball, source_dir.join(release_tarball.basename))

        # docker entry point
        cp(docker_entrypoint, source_dir.join(release_entrypoint.basename))

        # Copy the OpenJDK repo file
        cp(adoptium_repo_file, source_dir.join(adoptium_repo_file.basename))
      end

      # we copy README.md.erb from the root dist/shared dir
      readme = shared_dist_dir.join('README.md.erb')
      cp(readme, source_dir.join('README.md.erb'))

      # The dod Docker image is part of the artifacts we want to keep
      render_container

      # Now let's try to build the generated container
      docker_command = ['docker', 'build', '--file', release_dockerfile, '-t', tag] + build_args + ['.']

      # Run the docker build -- so we are sure it builds
      Dir.chdir(release_dir) do
        puts "Working in #{release_dir}"
        run_docker(docker_command)
      end

      # TODO: we should start and smoke-test the container with
      # a docker compose file that also runs an Elastic container.
      if save
        # Once all file have been produced we can create a tarball
        puts 'Saving docker context into a tarball'

        tarball_filename = "enterprise-search#{image_environment}-#{package_version}-docker-context#{image_suffix}.tar.gz"
        tarball = PROJECT_ROOT.join('release', tarball_filename)

        puts "Producing #{tarball}"
        `tar -czf #{tarball} -C #{release_dir} .`

        if @is_ironbank_release
          create_ironbank_dist(tarball, package_version)
        end
      end

      # getting rid of our readme copy
      source_dir.join('README.md.erb').unlink
    end

    def create_ironbank_dist(tarball, package_version)
      puts('Cleaning up and creating Ironbank distribution...')

      # extract tarball to temp directory
      tmp_directory = PROJECT_ROOT.join('release', 'tmp_ironbank')
      FileUtils.mkdir_p(tmp_directory)
      `tar -xzf #{tarball} -C #{tmp_directory}`

      # remove any artifacts downloaded via the manifest
      @manifest_downloads.each do |download_target|
        filename = File.basename(download_target)
        filepath = PROJECT_ROOT.join('release', 'tmp_ironbank', filename)
        File.delete(filepath) if File.exist?(filepath)
      end

      # Remove unwanted Adoptium repo from DOD image
      adoptium_repo_file = PROJECT_ROOT.join('release', 'tmp_ironbank', 'scripts', 'adoptium.repo')
      File.delete(adoptium_repo_file) if File.exist?(adoptium_repo_file)

      output = PROJECT_ROOT.join('release', "enterprise-search-ironbank-dod-docker-#{package_version}.tar.gz")
      puts "Producing #{output}"
      `tar -czf #{output} -C #{tmp_directory} .`

      # cleanup
      FileUtils.remove_dir(tmp_directory)
    end

    def render_container
      puts "Creating #{@name}'s Docker distribution in #{release_dir}"

      # we copy each file from `dist/shared/<name>` to `release_dir`
      source_dir = shared_dist_dir.join(@name).to_s

      Dir.glob("#{source_dir}/**/*").each do |source|
        next if File.directory?(source)

        is_erb = File.extname(source) == '.erb'
        if is_erb
          puts "=> Rendering ERB #{source}"
          rendered_source = render_erb(source)
          puts "=> Generated #{rendered_source}"
          source = rendered_source
        end

        target = release_dir.join(source.delete_prefix("#{source_dir}/")).to_s
        puts "=> Adding #{target}"
        FileUtils.mkdir_p(File.dirname(target))
        File.delete(target) if File.exist?(target)
        cp(source, target)

        # special case: the manifest
        # Download files required to build the image

        if target.end_with?('hardening_manifest.yaml') && @process_manifest
          puts '=> Reading the manifest'
          manifest = Manifest.new(target)
          manifest.download_binaries(release_dir).each do |downloaded|
            downloaded_target = release_dir.join(downloaded.delete_prefix("#{source_dir}/")).to_s
            puts "=> Adding the resource: #{downloaded_target}"
            @manifest_downloads.append(downloaded_target)
          end
        end
      end

      release_dir
    end

    def _download(url)
      puts("Downloading: #{url}")
      ssl_verify_mode =
        if ENV.has_key?('INSECURE')
          OpenSSL::SSL::VERIFY_NONE
        else
          OpenSSL::SSL::VERIFY_PEER
        end
      Retriable.retriable do
        Down.download(url, ssl_verify_mode: ssl_verify_mode, headers: { 'Cache-Control' => 'no-cache' }).read
      end
    end

    def _download_json(url)
      JSON.parse(_download(url))
    end

    def get_latest_public_version(major)
      url = 'https://artifacts-api.elastic.co/v1/versions'
      puts "=> Reading #{url}"
      versions = _download_json(url)['versions']

      if @is_ironbank_release
        puts('... not allowing SNAPSHOT builds...')
        versions.select! { |version| version.start_with?(major) && !version.end_with?('-SNAPSHOT') }
      else
        versions.select! { |version| version.start_with?(major) }
      end

      versions.sort_by { |version| Gem::Version.new(version) }
      versions[-1].delete_suffix('-SNAPSHOT')
    end

    def retrieve_elastic_artifacts_release_info
      # We're getting the latest tarball release for the given version
      version_tag = @is_ironbank_release ? product_version : "#{product_version}-SNAPSHOT"
      url = "https://artifacts-api.elastic.co/v1/versions/#{version_tag}/builds/latest/projects/ent-search/packages"

      puts "=> Reading #{url}"
      packages = _download_json(url)['packages']
      packages = packages.map do |key, value|
        next if value.has_key?('architecture') && value['architecture'] == 'aarch64'
        value if value['type'] == 'tar' && key.end_with?('.tar.gz')
      end.compact

      # variables used in the template
      @snapshot_url = packages[0]['url']
      @snapshot_tarball = packages[0]['url'].split('/')[-1]
      @snapshot_sha = _download(packages[0]['sha_url']).split(' ')[0]

      # this is going to be our release for the Dockerfile
      @release_tarball = top_release_dir.join(snapshot_tarball)
    end

    def render_erb(template)
      template_data = File.read(template)
      erb = ERB.new(template_data)
      target = template.delete_suffix('.erb')
      File.delete(target) if File.exist?(target)
      File.write(target, erb.result(binding))
      target
    end

    def docker_labels
      {}.tap do |labels|
        labels['org.opencontainers.image.title']    = product_name
        labels['org.opencontainers.image.version']  = package_version
        labels['org.opencontainers.image.vendor']   = 'Elastic'
        labels['org.opencontainers.image.licenses'] = 'Elastic License'
        labels['org.opencontainers.image.url']      = "https://www.elastic.co/solutions/#{product_name}"
        labels['org.opencontainers.image.description'] = product_description
        labels['mil.dso.ironbank.product.name'] = 'Enterprise Search'
      end
    end

  end
end