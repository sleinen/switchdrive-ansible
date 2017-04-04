
rm -rf /mnt/*/elasticsearch on both servers

ansible-playbook -i inventories/xxxx playbooks/elkservers.yml -t elasticsearch

on elk1:
#curl -XPUT 'http://localhost:9200/_all/_settings?preserve_existing=true' -d '{
#  "index.number_of_replicas" : "0"
#}'

check with

curl -XGET "http://localhost:9200/_cat/nodes?v"
