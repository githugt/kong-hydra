# Source: https://stackoverflow.com/questions/62210475/how-to-add-community-plugins-in-kong-installed-using-docker
# FROM kong:latest
FROM kong:2.5  
USER root
COPY kong.yml /
RUN apk update && apk add git unzip luarocks
RUN luarocks install kong-oidc  
USER kong