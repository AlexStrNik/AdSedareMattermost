# frozen_string_literal: true

require_relative "lib/adsedare_mattermost/version"

Gem::Specification.new do |spec|
  spec.name = "adsedare_mattermost"
  spec.version = AdsedareMattermost::VERSION
  spec.authors = ["alexstrnik"]
  spec.email = ["alex.str.nik@gmail.com"]

  spec.summary = "AdSedare 2FA Provider via Mattermost bot"
  spec.description = "AdSedare 2FA Provider via Mattermost bot"
  spec.homepage = "https://github.com/AlexStrNik/AdsedareMattermost"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/AlexStrNik/AdsedareMattermost"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "adsedare", "~> 0.0.6"
  spec.add_dependency "faraday", "~> 2.7"
end
