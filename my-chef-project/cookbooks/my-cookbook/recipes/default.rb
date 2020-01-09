#
# Cookbook:: my-cookbook
# Recipe:: default
#
# Copyright:: 2019, The Authors, All Rights Reserved.
#
apt_update
package 'python3'
package 'python3-pip'
package 'nginx'
package 'pkg-config'
package 'libcairo2-dev' 
package 'libjpeg-dev'
package 'libgif-dev'

user 'bob' do
uid 1212
gid 'users'
home '/home/bob'
shell '/bin/bash'
password '$1$alilbito$C83FsODuq0A1pUMeFPeR10'
end

remote_directory '/home/bob/myapp' do
source 'myapp' # This is the name of the folder containing our source code that we kept in ./my-cookbook/files/default/
owner 'bob'
group 'users'
mode '0755'
action :create
end

execute 'install python dependencies' do
command 'pip3 install -r requirements.txt'
cwd '/home/bob/myapp'
end

systemd_unit 'gunicorn.service' do
content({Unit: {
Description: 'Django on Gunicorn',
After: 'network.target',
},
Service: {
ExecStart: '/usr/local/bin/gunicorn --workers 3 "bind localhost:8080 myapp.wsgi:application"',
User: 'bob',
Group: 'www-data',
WorkingDirectory: '/home/bob/myapp',
Restart: 'always',
},
Install: {
WantedBy: 'multi-user.target',
}})
action [:create, :enable, :start]
end

template '/etc/nginx/sites-available/example.com.conf' do
source 'nginx.conf.erb'
owner 'root'
group 'root'
mode '0744'
end

link '/etc/nginx/sites-enabled/example.com.conf' do
to '/etc/nginx/sites-available/example.com.conf'
end

firewall 'default' # This will install and enable the Uncomplicated Firewall (or UFW) on Debian.
firewall_rule 'open_tcp_port_eighty' do
port 80
protocol :tcp
command :allow
end
