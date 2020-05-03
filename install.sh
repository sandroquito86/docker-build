# Config and Install Odoo Server
# Author: Joynal Framet Olimpo - 2020
# Collaborator: Chrystiam Toapaxi Acosta

. ./.env

# Date Config
if [ -f /etc/localtime/ ]; then
  cp /usr/share/zoneinfo/America/Guayaquil /etc/localtime 
fi

dt=$(date '+%d-%m-%Y--%H-%M-%S')

# For backup environment directory
if [ ! -d "$ODOO_BACKUP" ]; then
    mkdir "$ODOO_BACKUP"
fi

# Security Backup
if [ -d "$ODOO_PATH" ]; then
     mv "$ODOO_PATH" "$ODOO_BACKUP/$ODOO_VERSION.$dt"
     rm -rf "$ODOO_PATH"
fi

# Install docker - docker-compose
. /etc/os-release
SO=$ID

# Install docker and docker-compose Centos
if [ "$SO" = "centos" ]; then
     echo "(tput setaf 4)***************** UPDATE SO ************************************************$(tput setaf 3)"
     yum -y update
     echo "(tput setaf 4)***************** INSTALLING DEPENDS ***************************************$(tput setaf 3)"
     yum install -y yum-utils device-mapper-persistent-data lvm2 --no-install-recommends
     yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
     echo "(tput setaf 4)***************** INSTALL DOCKER ******************************************$(tput setaf 3)"
     yum install -y docker-ce
     usermod -aG docker $(whoami)
     gpasswd -a ${USER} docker
     systemctl enable docker.service
     systemctl start docker.service
     yum install -y epel-release
     echo "(tput setaf 4)*************** INSTALL Python-pip ****************************************$(tput setaf 3)"
     yum install -y python-pip --no-install-recommends
     echo "(tput setaf 4)************** INSTALL DOCKER-COMPOSE *************************************$(tput setaf 3)"
     pip install docker-compose --no-install-recommends
     echo "(tput setaf 4)************* Upgrade Python *********************************************$(tput setaf 3)"
     yum -y upgrade python --no-install-recommends
     docker version
     docker-compose version
fi

if [ "$SO" = "ubuntu" ]; then
     echo "$(tput setaf 4)***************** UPDATE SO ************************************************$(tput setaf 3)"
     apt-get update -y
     echo "$(tput setaf 4)***************** INSTALL GIT ******************************************$(tput setaf 3)"
     apt-get install git
     echo "$(tput setaf 4)***************** INSTALL DOCKER ******************************************$(tput setaf 3)"
     apt-get -y install docker.io --no-install-recommends
     echo "$(tput setaf 4)***************** INSTALL DOCKER-COMPOSE******************************************$(tput setaf 3)"
     apt-get -y install docker-compose --no-install-recommends
     echo "$(tput setaf 4)***************** INFORMATION DOCKER******************************************$(tput setaf 3)"
     groupadd -f docker
     usermod -aG docker $(whoami)
     newgrp docker << END
END
     docker version
     docker-compose version
fi

if [ ! -d "$ODOO_PATH/$ODOO_VERSION" ]; then
    mkdir -p "$ODOO_PATH/$ODOO_VERSION"
fi

# Donwload odoo git
if [ ! -d "$ODOO_PATH/$ODOO_VERSION/$ODOO_LOCAL_SRC/" ]; then
echo "$(tput setaf 4)***************** Clonando proyecto de Odoo de la comunidad de Odoo en Github *********************$(tput setaf 3)"
mkdir "$ODOO_PATH/$ODOO_VERSION/$ODOO_LOCAL_SRC/" && git clone --depth 1 https://github.com/odoo/odoo.git "$ODOO_PATH/$ODOO_VERSION/$ODOO_LOCAL_SRC/"
fi

chmod -R 777 "$ODOO_PATH/$ODOO_VERSION/"

# Build Odoo Image
#echo "$(tput setaf 4)***************** Construyendo imagen odoo: $ODOO_VERSION *********************$(tput setaf 3)"
make build

# Copy odoo configuration file in new project
if [ ! -f "$ODOO_PATH/$ODOO_VERSION/$CONF_LOCAL_PATH/odoo.conf" ]; then
    echo "$(tput setaf 4)***************** Copiando archivo odoo.conf en ruta de proyecto*********************$(tput setaf 3)"
    mkdir "$ODOO_PATH/$ODOO_VERSION/$CONF_LOCAL_PATH/" &&  cp ./odoo.conf "$ODOO_PATH/$ODOO_VERSION/$CONF_LOCAL_PATH/"
fi

chmod +x ./entrypoint.sh ./wait-for-psql.py
chmod -R 777 "$ODOO_PATH"

#echo "$(tput setaf 1)****************** Levantando Servicios *******************************$(tput setaf 3)"
make compose

chmod -R 777 "$ODOO_PATH"

make logs