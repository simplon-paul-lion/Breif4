#cloud-config
package_update: true
packages:
  - docker.io

runcmd:
  - docker run --restart unless-stopped -e REDIS=${REDIS_HOST} -e REDIS_PWD=${REDIS_PWD} -e REDIS_TLS=ON -p 80:80 whujin11e/public:azure_voting_app
