# Author:: Paul Mooring <paul@opscode.com>
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module KnifeSuppport
  class Support < Chef::Knife
    banner "knife support [HOST] (options)"

    # Don't lazy load or you'll get an error
    require 'chef/environment'
    require 'chef/node'
    require 'chef/role'
    require 'chef/api_client'
    # Do lazy load this stuff
    deps do
      require 'chef/knife/ssh'
      require 'chef/mixin/command'
      require 'net/ssh'
      require 'net/ssh/multi'
    end

    [:knife, :nodes, :roles, :environments, :clients, :databags].each do |opt|
      option opt,
          :short => "-#{opt.to_s[0]}",
          :long => "--#{opt.to_s}",
          :boolean => true,
          :description => "Include details on #{opt.to_s}"
    end

    option :all,
        :short => '-a',
        :long => '--all',
        :boolean => true,
        :description => "Include everything (except data bags)"

    option :really_all,
        :short => '-A',
        :long => '--really-all',
        :boolean => true,
        :description => "Include everything (including data bags)"

    option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username"

    option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

    option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

    option :connect_attribute,
        :short => "-C ATTR",
        :long => "--connect-attribute ATTR",
        :description => "The attribute to use for opening the connection - default is fqdn",
        :default => "fqdn"

    option :use_sudo,
        :long => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean => true

    option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

    [Chef::Environment, Chef::Role, Chef::Node, Chef::ApiClient, Chef::DataBag].each do |klass|
      component = klass.to_s.downcase.gsub("chef::", "").concat('s')
      define_method "get_#{component}".to_sym do
        msg "==== #{component} ===="
        klass.list.each do |name, uri|
          msg "=== #{name} ===" 
          output format_for_display(klass.load(name))
          msg "=== End #{name} ===" 
        end
        msg "==== End #{component} ===="
      end
    end

    def knife_ssh(host)
      command = if config[:use_sudo]
        "sudo chef-client -l debug"
      else
        "chef-client -l debug"
      end

      ssh = Chef::Knife::Ssh.new
      ssh.ui = ui
      ssh.name_args = [ host, command ]
      ssh.config[:ssh_user] = config[:ssh_user]
      ssh.config[:ssh_user] ||= 'root'
      ssh.config[:ssh_password] = config[:ssh_password]
      ssh.config[:ssh_port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
      ssh.config[:identity_file] = config[:identity_file]
      ssh.config[:manual] = true
      ssh.config[:host_key_verify] = config[:host_key_verify]
      ssh.config[:on_error] = :raise
      ssh.config[:attribute] = config[:connect_attribute]
      begin
        ssh.run
      rescue Net::SSH::AuthenticationFailed
        if ssh.config[:ssh_password].nil?
          msg "Failed to authenticate #{config[:ssh_user]} - trying password auth"
          config[:ssh_password] ||= ui.ask("Enter your password: ") { |q| q.echo = false }
          knife_ssh(host)
        end
      end
    end

    def get_config
      msg "==== configuration ===="
      msg "=== config ==="
      pp config
      msg "=== End config ==="
      msg "=== Chef::Config ==="
      pp Chef::Config.configuration
      msg "=== End Chef::Config ==="
      msg "==== End configuration ===="
    end

    def run
      unless config[:knife] or config[:nodes] or config[:roles] or config[:environments] or config[:clients] or config[:databags]
        config[:all] = true
      end
      if config[:really_all]
        config[:all] = true
        warn "The --really-all will include your data bags and data contained in them."
        confirm "Do you want to continue"
      elsif config[:databags]
        warn "The --databags will include your data bags and data contained in them."
        confirm "Do you want to continue"
      end

      get_config if config[:knife] or config[:all]
      get_nodes if config[:nodes] or config[:all]
      get_roles if config[:roles] or config[:all]
      get_environments if config[:environments] or config[:all]
      get_apiclients if config[:clients] or config[:all]
      get_databags if config[:databags] or config[:really_all]
      knife_ssh name_args.first if name_args.first
    end
  end
end
