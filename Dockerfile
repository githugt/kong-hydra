FROM kong:latest  
USER root
COPY kong.yml /
COPY kong.conf /etc/kong/kong.conf
RUN apk update && apk add git unzip luarocks
RUN luarocks install kong-oidc  
USER kong