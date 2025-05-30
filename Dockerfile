FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive

VOLUME [ \
  "/home/frappeuser/erpnext-bench/sites", \
  "/home/frappeuser/erpnext-bench/sites/assets", \
  "/home/frappeuser/erpnext-bench/logs" \
  "/var/lib/mysql", \
]

RUN apt update && \
    apt install -y \
    curl \
    vim \
    libpango-1.0-0 \
    libharfbuzz0b \
    libpangoft2-1.0-0 \
    libpangocairo-1.0-0 \
    libjpeg62-turbo \
    xfonts-base \
    restic \
    gpg \
    wget \
    git \
    sudo \
    python-is-python3 \
    python3-dev \
    python3-pip \
    redis-server \
    libmariadb-dev \
    mariadb-server \
    mariadb-client \
    cron \
    python3.11-venv \
    xfonts-75dpi \
    pkg-config \
    fontconfig \
    xvfb \
    libfontconfig && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /usr/local/bin/start.sh

RUN service mariadb start && \
    mariadb-secure-installation <<EOF

y
y
m
m
y
y
y
y
EOF

COPY my.cnf /etc/mysql/my.cnf

RUN service mariadb restart

ARG USERNAME=frappeuser
ARG USER_PASSWORD=m
ARG USER_UID=1000
ARG USER_GID=1000

# Create a non-root user and group
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME}

RUN echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
RUN usermod -aG sudo ${USERNAME}
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/90-${USERNAME} && \
    chmod 0440 /etc/sudoers.d/90-${USERNAME}

USER ${USERNAME}

ENV HOME=/home/${USERNAME}
WORKDIR /home/${USERNAME}

# Install nodejs and yarn
RUN sudo curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash - && \
    sudo apt install -y nodejs
RUN node -v
RUN sudo npm install -g yarn

ARG WKHTMLTOX_VERSION=0.12.6.1-3
ARG WKHTMLTOX_FILE=wkhtmltox_${WKHTMLTOX_VERSION}.bookworm_amd64.deb

RUN wget -P /tmp https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOX_VERSION}/${WKHTMLTOX_FILE}
RUN sudo dpkg -i /tmp/${WKHTMLTOX_FILE}
RUN sudo rm /tmp/${WKHTMLTOX_FILE}

RUN sudo pip install frappe-bench --break-system-packages

RUN bench --version

ARG FRAPPE_BRANCH=version-15
ARG FRAPPE_PATH=https://github.com/frappe/frappe

RUN bench init \
    --frappe-branch=${FRAPPE_BRANCH} \
    --frappe-path=${FRAPPE_PATH} \
    --verbose \
    /home/frappeuser/erpnext-bench

RUN sed -i 's/13000/6379/g' /home/frappeuser/erpnext-bench/sites/common_site_config.json
RUN sed -i 's/11000/6379/g' /home/frappeuser/erpnext-bench/sites/common_site_config.json

EXPOSE 8000
EXPOSE 9000

WORKDIR /home/${USERNAME}/erpnext-bench

RUN sudo service mariadb start && \
    sudo service redis-server start && \
    bench new-site erpnext.localhost --admin-password m --mariadb-root-password m --mariadb-root-username root && \
    bench get-app --branch version-15 payments && \
    bench get-app --resolve-deps --branch version-15 erpnext https://github.com/ma2erp/erpnext && \
    bench get-app  --branch version-15 hrms && \
    bench --site erpnext.localhost install-app erpnext && \
    bench --site erpnext.localhost install-app payments && \
    bench --site erpnext.localhost install-app hrms

RUN sudo apt update && sudo apt install -y netcat-traditional
RUN sudo chmod +x /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]