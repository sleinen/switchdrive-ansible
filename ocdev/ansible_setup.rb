def setup_ansible(box, host_name) 
  box.vm.provision "ansible" do |ansible|
    ansible.playbook = "ocdev_playbook.yml"
    ansible.groups = {
     "owncloud" => ["ocapp"],
     "all_groups:children" => ["owncloud"]
    }
  end
end