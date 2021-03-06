#!/bin/bash

# This script generates params.default for SiloDatabaseServer SiloDatabaseClient:
#if [ $# -ne 3 ]; then
#	echo "Usage: exec n_client_node n_client_per_node n_rooms"
#	exit 1
#fi

nodeset=hosts
n_client_per_node=16
n_client_node=1
n_rooms=4

n_client_per_excomm=8

mace_port=6501

n_clients=$(($n_client_node * $n_client_per_node))
n_excomms=$(($n_clients / $n_client_per_excomm ))

server_params_conf="server/params.default"
cp server/params.default.basic $server_params_conf

head_nodeId=$(($n_client_node + 1))
first_worker_nodeId=0

head_node=""
cur_nodeId=1
server_node_number=0
server_node_iter=1
while read node
do
	if [ $cur_nodeId -eq $head_nodeId ]; then
		head_node=$node
		first_worker_nodeId=$(($cur_nodeId+1))
	fi
	
	if [ $n_client_node -lt $cur_nodeId ]; then
		server_node_number=$(( $server_node_number+1 ))	
	fi

	cur_nodeId=$(( $cur_nodeId+1  ))
done < $nodeset

n_departments=$server_node_number
n_worker_node=$(( $server_node_number - 1));

echo "NUM_EXTERNAL_COMMUNICATION_CONTEXT = $n_excomms" >> $server_params_conf
echo "ServiceConfig.ElasticTagAppServer.N_ROOMS = $n_rooms" >> $server_params_conf


cur_nodeId=1
while read node
do
	if [ $cur_nodeId -le $n_client_node ]; then
		params_conf="client/params.default.client$cur_nodeId"
		cp client/params.default.basic $params_conf
		echo "ServiceConfig.ElasticTagAppClient.HeadNode = IPV4/$head_node:$mace_port" >> $params_conf
		echo "ServiceConfig.ElasticTagAppClient.N_CLIENTS = $n_client_per_node" >> $params_conf

		echo "lib.ContextJobApplication.nodeset = IPV4/$node:$mace_port" >> $params_conf
		echo "nodeset = $node:$mace_port" >> $params_conf
		
		if [ $cur_nodeId -eq 1 ]; then
			echo $node > client/nodeset-client
		else
			echo $node >> client/nodeset-client
		fi
	else
		echo "lib.ContextJobApplication.nodeset = IPV4/$node:$mace_port" >> $server_params_conf
		echo "nodeset = $node:$mace_port" >> $server_params_conf
		SERVERNODE[$server_node_iter]=$node
		server_node_iter=$(( $server_node_iter + 1 ))
		if [ $cur_nodeId -eq $head_nodeId ]; then
			echo $node > server/nodeset-server-head
		elif [ $cur_nodeId -eq $first_worker_nodeId ]; then
			echo $node > server/nodeset-server-worker
		else
			echo $node >> server/nodeset-server-worker
		fi
	fi
	cur_nodeId=$(( $cur_nodeId+1 ))
done < $nodeset

for (( ext_iter=0, node_iter=0; ext_iter<$n_excomms; ext_iter++ )); do
	echo "mapping = $node_iter:externalCommContext[$ext_iter]" >> $server_params_conf
	node_iter=$(( ($node_iter+1) % $server_node_number ))
done


init_n_server=$(( $server_node_number / 4 ))
#init_n_server=$server_node_number
#init_n_server=$(( $server_node_number / 2 ))
#nit_n_server=22

for (( r_iter=1,  node_iter=0; r_iter<=$n_departments; r_iter++)); do
	echo "mapping = $node_iter:Room[$r_iter]" >> $server_params_conf
	node_iter=$(( ($node_iter+1) % $init_n_server))
done

start_rid=1
end_rid=$n_rooms

min_n_server=$(( $server_node_number/4 ))
mid_n_server=$(( $server_node_number/2 ))
max_n_server=$server_node_number

for (( riter=$start_rid; riter<=$end_rid; riter++ )); do
	nodeId=$(( ($riter-1) % $min_n_server + 1  ))
	nextNodeId=$(( ($riter-1) % $mid_n_server + 1 ))
	if [ $nodeId -ne $nextNodeId ]; then
		#echo "################ migrate-R[$riter]" >> $server_params_conf
		migrateid="migrate_scaleup_R${riter}_R1"
		echo "$migrateid.service = 0" >> $server_params_conf
		echo "$migrateid.dest = ${SERVERNODE[$nextNodeId]}" >> $server_params_conf
		echo "$migrateid.contexts = Room[$riter]" >> $server_params_conf
		echo "   " >> $server_params_conf
	fi				
	
	nodeId=$nextNodeId
	nextNodeId=$(( ($riter-1) % $max_n_server + 1 ))
	if [ $nodeId -ne $nextNodeId ]; then
		#echo "################ migrate-R[$riter]" >> $server_params_conf
		migrateid="migrate_scaleup_R${riter}_R2"
		echo "$migrateid.service = 0" >> $server_params_conf
		echo "$migrateid.dest = ${SERVERNODE[$nextNodeId]}" >> $server_params_conf
		echo "$migrateid.contexts = Room[$riter]" >> $server_params_conf
		echo "   " >> $server_params_conf
	fi	

	nodeId=$nextNodeId
	nextNodeId=$(( ($riter-1) % $mid_n_server + 1 ))
	if [ $nodeId -ne $nextNodeId ]; then
		#echo "################ migrate-R[$riter]" >> $server_params_conf
		migrateid="migrate_scaledown_R${riter}_R2"
		echo "$migrateid.service = 0" >> $server_params_conf
		echo "$migrateid.dest = ${SERVERNODE[$nextNodeId]}" >> $server_params_conf
		echo "$migrateid.contexts = Room[$riter]" >> $server_params_conf
		echo "   " >> $server_params_conf
	fi

	nodeId=$nextNodeId
	nextNodeId=$(( ($riter-1) % $min_n_server + 1 ))
	if [ $nodeId -ne $nextNodeId ]; then
		#echo "################ migrate-R[$riter]" >> $server_params_conf
		migrateid="migrate_scaledown_R${riter}_R1"
		echo "$migrateid.service = 0" >> $server_params_conf
		echo "$migrateid.dest = ${SERVERNODE[$nextNodeId]}" >> $server_params_conf
		echo "$migrateid.contexts = Room[$riter]" >> $server_params_conf
		echo "   " >> $server_params_conf
	fi	
done

