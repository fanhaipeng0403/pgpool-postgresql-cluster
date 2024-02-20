FROM centos:7

ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

RUN yum -y install epel-release  openssh-clients iptables acl iproute; yum -y install openssh-server; yum -y install python3 python-pip sshpass; yum -y install nodejs; yum clean all; systemctl enable sshd.service

RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN ssh-keygen -A

# Install Ansible via Pip.
RUN pip3 install ansible -i https://mirrors.aliyun.com/pypi/simple

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts


# Install Jupyter via Pip.
RUN pip3  install jupyter jupyterlab -i https://mirrors.aliyun.com/pypi/simple
RUN mkdir -p /root/.jupyter
RUN echo "c.NotebookApp.password = u'sha1:734a34d3a8bc:674c6204b76bbd29096f7f1f4422c440b445dfff'" > /root/.jupyter/jupyter_notebook_config.py
COPY entrypoint.sh /

EXPOSE 22
EXPOSE 8888

ENTRYPOINT ["/entrypoint.sh"]
