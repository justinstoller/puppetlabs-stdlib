#! /usr/bin/env ruby -S rspec
require 'beaker-rspec'

UNSUPPORTED_PLATFORMS = []
NIGHTLY_MSI = "http://nightlies.puppetlabs.com/puppet-agent-latest/repos/windows/puppet-agent-%s.msi"

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'

  if default.is_pe?
    install_pe
  else
    if options[:type] == 'aio' and ENV['DEVEL_PUPPET']
      hosts.each do |host|

        if host['platform'] =~ /windows/
          arch = host.is_x86_64? ? 'x64' : 'x86'
          install_puppet_from_msi(host, :url => NIGHTLY_MSI % arch)
        else
          install_puppetlabs_dev_repo(host, 'puppet-agent', ENV['PUPPET_AGENT_VERSION'] || '1.0.0')
          install_package(host, 'puppet-agent')
        end

        if host['roles'].include?('master')
          install_puppetlabs_dev_repo(host, 'puppetserver', ENV['PUPPET_SERVER_VERSION'] || '2.0.0')
          install_package(host, 'puppetserver')
        end
      end

    elsif options[:type] == 'aio'
      install_puppet(:version              => ENV['PUPPET_VERSION'] || '4.0.0',
                     :puppet_agent_version => ENV['PUPPET_AGENT_VERSION'] || '1.0.0',
                     :default_action       => 'gem_install'                             )

    else
      install_puppet(:version        => ENV['PUPPET_VERSION'] || '3.7.2',
                     :default_action => 'gem_install'                     )
    end
  end

  hosts.each do |host|
    if host['platform'] !~ /windows/i
      on host, "/bin/touch #{host['puppetpath']}/hiera.yaml"
      on host, "mkdir -p #{host['distmoduledir']}"
      on host, "mkdir -p #{host.puppet['pluginfactdest']}"
    end
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    if ENV['FUTURE_PARSER'] == 'true'
      default[:default_apply_opts] ||= {}
      default[:default_apply_opts].merge!({:parser => 'future'})
    end

    copy_root_module_to(default, :source => proj_root, :module_name => 'stdlib')
  end
end

def is_future_parser_enabled?
  if default[:default_apply_opts]
    return default[:default_apply_opts][:parser] == 'future'
  end
  return false
end
