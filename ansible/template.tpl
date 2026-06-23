[k3s_master]
${k3s_master_id}

[k3s_master:vars]
master_ip=${k3s_master_ip}

[k3s_workers_app]
%{ for idx, id in k3s_worker_ids ~}
%{ if worker_roles[idx] == "app" ~}
${id}
%{ endif ~}
%{ endfor ~}

[k3s_workers_data]
%{ for idx, id in k3s_worker_ids ~}
%{ if worker_roles[idx] == "data" ~}
${id}
%{ endif ~}
%{ endfor ~}

[k3s_workers:children]
k3s_workers_app
k3s_workers_data

[all:vars]
ansible_connection=amazon.aws.aws_ssm
ansible_aws_ssm_region=${aws_region}
ansible_aws_ssm_bucket_name=${bucket_name}
