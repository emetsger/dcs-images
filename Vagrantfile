# -*- mode: ruby -*-
# vi: set ft=ruby :
#
Vagrant.require_version ">= 1.6.0"

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'docker'
 
Vagrant.configure("2") do |config|

  # Do not share the current directory as /vagrant with Docker
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.define "dcs-container" do |m|
 
    m.vm.provider :docker do |d|
      d.name = 'dcs-container'
      d.build_dir = "docker/dcs-all"
      d.cmd = ["launch.sh"]
      d.volumes = ["/shared:/shared"]
      d.expose = [8080, 8081]
      d.ports = ["8080:8080", "8181:8181"]
      d.remains_running = true

      # By default, this runs as the vagrant user
      d.create_args = ["--user=1000:1000"]

      # Comment out 'force' for direct docker on Linux
      d.force_host_vm = true
      d.vagrant_machine = "dockerhost"
      d.vagrant_vagrantfile = "./DockerHostVagrantfile"
    end
  end
end
