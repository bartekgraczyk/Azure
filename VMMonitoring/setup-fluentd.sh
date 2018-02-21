#!/bin/bash

logStorageAccountName=${1}
logStorageAccountKey=${2}

#yum checkupdate returns non zero when there is anything to update. disable for now.
#set -e

config_td_agent_log_to_storage() {
cat >> /etc/td-agent/td-agent.conf <<EOF
<source>
  @type tail
  path /var/log/azure/Microsoft.ManagedIdentity.ManagedIdentityExtensionForLinux/1.0.0.10/*
  pos_file /var/log/td-agent/buffer/msi.pos
  <parse>
    @type none
  </parse>
  tag msi.extension
</source>
<match msi.extension>
  @type azurestorage
  azure_storage_account    ${logStorageAccountName}
  azure_storage_access_key ${logStorageAccountKey}
  azure_container          msicontainer
  azure_storage_type       blob
  store_as                 gzip
  auto_create_container    true
  path                     logs/
  azure_object_key_format  %{path}%{time_slice}_%{index}.%{file_extension}
  time_slice_format        %Y%m%d%H%M  #write file every minute, default hour
  <buffer>
    @type file
    path /var/log/td-agent/buffer/azurestorage
    timekey 300 # 5 minute partition
    timekey_wait 1m # 1 minute wait to flush
    timekey_use_utc true # use utc
  </buffer>
</match>
#<match msi.extension>
#  @type s3
#  aws_key_id your_aws_key_id
#  aws_sec_key your_aws_key
#  s3_bucket msibucket
#  s3_region us-west-2
#  path logs/
#  s3_object_key_format  %{path}%{time_slice}_%{index}.%{file_extension}
#  time_slice_format %Y%m%d%H%M  #write file every minute, default hour
#  <buffer>
#    @type file
#    path /var/log/td-agent/buffer/s3
#    timekey 300 # 5 minute partition
#    timekey_wait 1m # 1 minute wait to flush
#    timekey_use_utc true # use utc
#  </buffer>
#</match>
EOF
}

install_td_agent_and_plugin() {
# the td-agent installation script below uses sudo which we cant do without tty
# so copy the content here
#curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent3.sh | sh

# add GPG key
rpm --import https://packages.treasuredata.com/GPG-KEY-td-agent

# add treasure data repository to yum
cat >/etc/yum.repos.d/td.repo <<'EOF';
[treasuredata]
name=TreasureData
baseurl=http://packages.treasuredata.com/3/redhat/\$releasever/\$basearch
gpgcheck=1
gpgkey=https://packages.treasuredata.com/GPG-KEY-td-agent
EOF

# update your sources, returns 100 if there is anything to update, breaks set -e
yum check-update
# install the toolbelt
yum install -y td-agent

td-agent-gem install fluent-plugin-azurestorage
}

install_td_agent_and_plugin
config_td_agent_log_to_storage
#by default, azure log, including extension log, is only readable by root, not by td_agent
chmod a+r /var/log/azure
systemctl start td-agent.service
                                              