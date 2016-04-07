# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require 'erb'

Vagrant.require_version ">= 1.6.0"


CLOUD_CONFIG_PATH_MASTER = File.join(File.dirname(__FILE__), "user-data-master.yml.erb")
CLOUD_CONFIG_PATH_WORKER = File.join(File.dirname(__FILE__), "user-data-worker.yml.erb")

CERT_PATH = 'tls/certs/'

CONFIG = File.join(File.dirname(__FILE__), "config.rb")

# Defaults for config options defined in CONFIG
$num_instances = 3 
$num_master = 3 
$instance_name_prefix = "core"
$update_channel = "alpha"
$image_version = "current"
$enable_serial_logging = false
$share_home = false
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1
$shared_folders = {}
$forwarded_ports = {}

# Attempt to apply the deprecated environment variable NUM_INSTANCES to
# $num_instances while allowing config.rb to override it
if ENV["NUM_INSTANCES"].to_i > 0 && ENV["NUM_INSTANCES"]
  $num_instances = ENV["NUM_INSTANCES"].to_i
end

if File.exist?(CONFIG)
  require CONFIG
end

# Use old vb_xxx config variables when set
def vm_gui
  $vb_gui.nil? ? $vm_gui : $vb_gui
end

def vm_memory
  $vb_memory.nil? ? $vm_memory : $vb_memory
end

def vm_cpus
  $vb_cpus.nil? ? $vm_cpus : $vb_cpus
end

Vagrant.configure("2") do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false

  config.vm.box = "coreos-%s" % $update_channel
  if $image_version != "current"
      config.vm.box_version = $image_version
  end
  config.vm.box_url = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [$update_channel, $image_version]

  ["vmware_fusion", "vmware_workstation"].each do |vmware|
    config.vm.provider vmware do |v, override|
      override.vm.box_url = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant_vmware_fusion.json" % [$update_channel, $image_version]
    end
  end

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  (1..$num_instances).each do |i|
    if i <= $num_master then
      vm_type = 'master'
    else
      vm_type = 'worker'
    end

    config.vm.define vm_name = "%s-%s-%02d" % [$instance_name_prefix, vm_type, i] do |config|
      config.vm.hostname = vm_name

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
        FileUtils.touch(serialFile)

        ["vmware_fusion", "vmware_workstation"].each do |vmware|
          config.vm.provider vmware do |v, override|
            v.vmx["serial0.present"] = "TRUE"
            v.vmx["serial0.fileType"] = "file"
            v.vmx["serial0.fileName"] = serialFile
            v.vmx["serial0.tryNoRxLoss"] = "FALSE"
          end
        end

        config.vm.provider :virtualbox do |vb, override|
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
      end

      if $expose_docker_tcp
        config.vm.network "forwarded_port", guest: 2375, host: ($expose_docker_tcp + i - 1), auto_correct: true
      end

      $forwarded_ports.each do |guest, host|
        config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
      end

      ["vmware_fusion", "vmware_workstation"].each do |vmware|
        config.vm.provider vmware do |v|
          v.gui = vm_gui
          v.vmx['memsize'] = vm_memory
          v.vmx['numvcpus'] = vm_cpus
        end
      end

      config.vm.provider :virtualbox do |vb|
        vb.gui = vm_gui
        vb.memory = vm_memory
        vb.cpus = vm_cpus
      end

      ip = "172.17.8.#{i+100}"
      config.vm.network :private_network, ip: ip

      # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
      config.vm.synced_folder ".", "/home/core/share"

      $shared_folders.each_with_index do |(host_folder, guest_folder), index|
        config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
      end

      if $share_home
        config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      end


      config.vm.provision :shell, :inline => "mkdir -p /tmp/certs/ && chown core:core /tmp/certs"
      # Provision Client-Server Certs
      puts "writing #{vm_name}.pem"
      config.vm.provision :file, :source => "tls/certs/#{vm_name}.pem", :destination => "/tmp/certs/#{vm_name}.pem"
      puts "writing #{vm_name}-key.pem"
      config.vm.provision :file, :source => "tls/certs/#{vm_name}-key.pem", :destination => "/tmp/certs/#{vm_name}-key.pem"
      # Provision Client Certs
      config.vm.provision :file, :source => "tls/certs/client.pem", :destination => "/tmp/certs/client.pem"
      config.vm.provision :file, :source => "tls/certs/client-key.pem", :destination => "/tmp/certs/client-key.pem"
      # Provision Peer Certs
      config.vm.provision :file, :source => "tls/certs/server.pem", :destination => "/tmp/certs/server.pem"
      config.vm.provision :file, :source => "tls/certs/server-key.pem", :destination => "/tmp/certs/server-key.pem"
      # Provision CA, but not key
      config.vm.provision :file, :source => "tls/certs/ca.pem", :destination => "/tmp/certs/ca.pem"

      # Move TLS into right folders, ensure correct permissions
      config.vm.provision :shell, :inline => <<-SCRIPT, :privileged => true
        echo 127.0.0.1 #{vm_name} >> /etc/hosts

        mkdir -p /etc/ssl/etcd/certs/client /etc/ssl/etcd/certs/private
        ls /tmp/certs/
        mv /tmp/certs/client* /etc/ssl/etcd/certs/client
        mv /tmp/certs/ca.pem /etc/ssl/etcd/certs/
        chmod +r /etc/ssl/etcd/certs/client/* /etc/ssl/etcd/certs/ca.pem
        mv /tmp/certs/#{vm_name}*.pem /etc/ssl/etcd/certs/private/
        mv /tmp/certs/server*.pem /etc/ssl/etcd/certs/private/
        chown -R etcd:etcd /etc/ssl/etcd/certs/private
      SCRIPT

      if vm_type == 'master' && File.exist?(CLOUD_CONFIG_PATH_MASTER) then

        # Template user-data, add vm_name to 
        user_data = ERB.new(File.read(CLOUD_CONFIG_PATH_MASTER)).result(binding)
        config.vm.provision :shell, :inline => "echo \"#{user_data}\" > /tmp/vagrantfile-user-data"
        config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      else vm_type == 'worker' && File.exist?(CLOUD_CONFIG_PATH_WORKER)
        user_data = ERB.new(File.read(CLOUD_CONFIG_PATH_WORKER)).result(binding)
        config.vm.provision :file, :source => "#{user_data}", :destination => "/tmp/vagrantfile-user-data"
        config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      end

    end
  end
end
