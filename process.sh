
dir_lab=/home/ezech/Git/github.com/ezech/lab
dir_ca=$dir_lab/lab-ca

key_root=$dir_ca/private/ca.key
crt_root=$dir_ca/certs/ca.crt

key_intermediate=$dir_ca/private/intermediate.key
crt_intermediate=$dir_ca/certs/intermediate.crt
csr_intermediate=${crt_intermediate/.crt/.csr}

key_smtp=$dir_ca/private/smtp.key
crt_smtp=$dir_ca/certs/smtp.crt
csr_smtp=${crt_smtp/.crt/.csr}

mkdir -p \
  $dir_ca/private \
  $dir_ca/certs
sudo mkdir -p /etc/pki/CA/


# root CA self-signed certificate
openssl req \
  -x509 \
  -sha256 \
  -newkey rsa:4096 \
  -noenc \
  -keyout $key_root \
  -days 3650 \
  -subj "/C=PL/ST=Silesia/L=Katowice/O=Playbox2Lab/OU=Lab/CN=Playbox2 CA Root" \
  -addext "subjectKeyIdentifier = hash" \
  -addext "authorityKeyIdentifier = keyid:always,issuer" \
  -addext "basicConstraints = critical, CA:true" \
  -addext "keyUsage = critical, digitalSignature, cRLSign, keyCertSign" \
  -out $crt_root

chmod 600 $key_root

# intermediate CA
openssl genrsa \
  -out $key_intermediate 4096
chmod 600 $key_intermediate

# intermediate csr
openssl req \
  -new \
  -subj "/C=PL/ST=Silesia/L=Katowice/O=Playbox/OU=Lab/CN=Playbox2 CA Intermediate" \
  -key $key_intermediate \
  -out $csr_intermediate

openssl x509 \
  -req \
  -days 10240 \
  -CA $crt_root \
  -CAkey $key_root \
  -CAcreateserial \
  -subj "/C=PL/ST=Silesia/L=Katowice/O=Playbox/OU=Lab/CN=Playbox2 CA Intermediate" \
  -ext "basicConstraints = critical, CA:true" \
  -ext "authorityKeyIdentifier = keyid:always,issuer" \
  -ext "keyUsage = critical, digitalSignature, cRLSign, keyCertSign" \
  -in  $csr_intermediate \
  -out $crt_intermediate

sudo cp lab-ca/certs/ca.crt /etc/pki/tls/certs/lab-ca.crt

# Certificate SMTP
openssl genrsa -out $key_smtp 4096
chmod 600 $key_smtp
openssl req \
  -new \
  -subj "/C=PL/ST=Silesia/L=Katowice/O=Playbox/OU=Lab/CN=Playbox2 SMTP" \
  -key $key_smtp \
  -out $csr_smtp

openssl x509
  -req \
  -sha256 \
  -CA    $crt_intermediate \
  -CAkey $key_intermediate \
  -CAcreateserial \
  -days 1024 \
  -extensions v3_req \
  -in  $csr_smtp \
  -out $crt_smtp

sudo dnf install postfix
# edit /etc/postfix/main.cnf
sudo systemctl start  postfix
sudo systemctl enable postfix

sudo cp $crt_smtp /etc/pki/tls/certs/postfix.pem
sudo cp $key_smtp /etc/pki/tls/private/postfix.key


curl \
  -sSf \
  "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/config_file.repo?os=fedora&dist=42&source=script" \
  > /etc/yum.repos.d/gitlab_gitlab-ce.repo

cat << EOF > /etc/yum.repos.d/gitlab_gitlab-ce.repo
[gitlab_gitlab-ce]
name=gitlab_gitlab-ce
baseurl=https://packages.gitlab.com/gitlab/gitlab-ce/fedora/42/x86_64
repo_gpgcheck=1
gpgcheck=1
enabled=1
gpgkey=https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey
       https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
       https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-CB947AD886C8E8FD.pub.gpg
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[gitlab_gitlab-ce-source]
name=gitlab_gitlab-ce-source
baseurl=https://packages.gitlab.com/gitlab/gitlab-ce/fedora/42/SRPMS
repo_gpgcheck=1
gpgcheck=1
enabled=1
gpgkey=https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey
       https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg
       https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-CB947AD886C8E8FD.pub.gpg
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF

dnf install gitlab-ce libxcrypt-compat
# edit /etc/gitlab/gitlab.rb
#Password: 50pljxUPTk9Hpi3OLSXf+ul+NYrKHSDt+HD/f0Rp9Ms=
sudo cat /etc/gitlab/initial_root_password
gitlab-ctl reconfigure

