FROM debian:latest AS stage-01
# Prepare for installation
RUN apt update 

FROM stage-01 as stage-02
# Install building tools
RUN apt install -y curl

FROM stage-02 as stage-02a

RUN echo "Build 0.1" > /version.txt

FROM stage-02 as stage-03

RUN apt install -y jq
