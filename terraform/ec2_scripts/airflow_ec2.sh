#!/bin/bash
#some ec2 debugging commands I used
journalctl -xef


cd testing_docker_stuff
sudo chmod -R 777 dags/ logs/ plugins/
sudo chmod -R 777 logs/

sudo docker compose build && sudo docker compose pull && sudo docker compose up


USER root
