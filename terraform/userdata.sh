#!/bin/bash -x
set -e

echo "Installing dependencies..."
yum update -y
yum install -y unzip wget python-setuptools git
easy_install pip
pip install awscli
git clone https://github.com/seporaitis/yum-s3-iam.git /tmp/yum-s3-iam
cp /tmp/yum-s3-iam/s3iam.py /usr/lib/yum-plugins/
cp /tmp/yum-s3-iam/s3iam.conf /etc/yum/pluginconf.d/

echo "Setting up consul s3 repository..."
cat > /etc/yum.repos.d/consul-server.repo <<EOF
[consul]
name=Consul S3 repository
baseurl=http://my-consul-s3-repo-bucket.s3.amazonaws.com/consul/server/centos/\$releasever/\$basearch
failovermethod=priority
enabled=1
s3_enabled=1
gpgcheck=0
EOF

echo "Installing consul"
yum install -y consul-server

echo "Allowing ingress connections"
iptables -I INPUT -m state --state NEW -m tcp -s 10.0.0.0/8 -p tcp --dport 8300 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -s 10.0.0.0/8 -p tcp --dport 8301 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -s 10.0.0.0/8 -p tcp --dport 8302 -j ACCEPT

service iptables save

REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F: '{print $NF}' | tr -cd '[[:alnum:]]-')
echo "{ \"server\": true, \"datacenter\": \"${REGION}\",\"data_dir\": \"/var/lib/consul\",\"log_level\": \"INFO\",\"enable_syslog\": true}" > /etc/consul.d/server/server.json
echo "export AWS_DEFAULT_REGION=${REGION}" > /etc/profile.d/awscli.sh
export AWS_DEFAULT_REGION=${REGION}

# find instance id
INSTANCEID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
# what asg spun up the instance
INSTANCE_ASG_NAME=$(aws --output=text ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCEID}" --query 'Tags[?Key==`aws:autoscaling:groupName`].Value')
# size of asg means size of cluster
CLUSTER_SIZE=$(aws --output=text autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${INSTANCE_ASG_NAME} --query 'AutoScalingGroups[].MaxSize')

# this will be used by consul-join service too
# to discover all nodes of the cluster
echo "INSTANCEID=${INSTANCEID}" > /etc/sysconfig/consul-server
echo "INSTANCE_ASG_NAME=${INSTANCE_ASG_NAME}" >> /etc/sysconfig/consul-server
echo "CLUSTER_SIZE=$CLUSTER_SIZE" >> /etc/sysconfig/consul-server

start consul-server
sleep 5
start consul-join
