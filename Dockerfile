FROM centos:7

LABEL maintainer="Okassov Marat"

# Download envs
ENV SPARK=http://apache.mirrors.hoobly.com/spark/spark-2.4.6/spark-2.4.6-bin-hadoop2.7.tgz
ENV GLUE=https://github.com/awslabs/aws-glue-libs.git
ENV MAVEN=https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-common/apache-maven-3.6.0-bin.tar.gz

ENV MAVEN_HOME /opt/apache-maven-3.6.0
ENV PATH $PATH:$MAVEN_HOME/bin
ENV PYTHONSTARTUP=/home/spark/.pythonrc
ENV PYTHONIOENCODING=utf8
ENV SPARK_HOME=/opt/spark
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.262.b10-0.el7_8.x86_64
ENV SPARK_CONF_DIR=/aws-glue-libs/conf
ENV PYTHONPATH=$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip:/aws-glue-libs/PyGlue.zip:$PYTHONPATH

# ENV SHA1 Pass for WEB Authentication
ENV WEB_PASSWORD_HASH=sha1:a6d79bec231c:214d737038ffb828f068a90912faa51992a97426

# Install tools
RUN yum install -y \
    java-1.8.0-openjdk-devel vim unzip \
    git wget zip

# Download Maven
RUN wget $MAVEN && \
    tar zxfv apache-maven-3.6.0-bin.tar.gz -C /opt && \
    rm -rf apache-maven-3.6.0-bin.tar.gz
 
# Download Spark
RUN curl -LO $SPARK && \
    tar zxvf spark-2.4.6-bin-hadoop2.7.tgz -C /opt && \
    ln -s /opt/spark-2.4.6-bin-hadoop2.7 /opt/spark && \
    rm -f spark-2.4.6-bin-hadoop2.7.tgz

# Download aws-glue-libs
RUN git clone -b glue-1.0 $GLUE

# (Optional) Nexus3 artifact manager
ADD pom.xml /aws-glue-libs/pom.xml

# Install aws-glue-libs
RUN sh /aws-glue-libs/bin/glue-setup.sh && \
    sed -e '/mvn/s/^/#/g' -i /aws-glue-libs/bin/glue-setup.sh && \
    sh /aws-glue-libs/bin/glue-setup.sh && \
    curl -L https://s3.eu-central-1.amazonaws.com/eugene.taranov.me/awsglue/glue-assembly.jar -o /opt/spark/jars/glue-assembly.jar && \
    curl -LO https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.11.tar.gz && \
    tar zxvf mysql-connector-java-8.0.11.tar.gz && \
    cp mysql-connector-java-8.0.11/mysql-connector-java-8.0.11.jar /opt/spark/jars/ && \
    rm -rf mysql-connector-java-8.0.11 mysql-connector-java-8.0.11.tar.gz && \
    rm -rf /aws-glue-libs/jarsv1/netty-all* && \
    cp /opt/spark/jars/netty-all-4.1.47.Final.jar /aws-glue-libs/jarsv1/

# Install python3, jupyter, and other
RUN yum install -y epel-release && yum clean all && \
    yum install -y python3-devel gcc python3 sudo && \
    pip3 install 'ipython' && \
    pip3 install jupyter jupyterthemes jupyter_contrib_nbextensions jupyter_contrib_nbextensions && \
    pip3 install boto3 botocore awscli py4j

# Python3 default
RUN rm -rf /usr/bin/python && rm -rf /usr/bin/pip && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    ln -s /usr/bin/pip3 /usr/bin/pip

# Configure jupyter
RUN mkdir -p /root/.local/share/jupyter/kernels/spark && \
    jupyter contrib nbextension install --user && \
    jupyter nbextensions_configurator enable --user && \
    jupyter notebook --generate-config && \
    sed -i '/^#.*c.NotebookApp.allow_password_change = True/s/^#c.NotebookApp.allow_password_change = True/c.NotebookApp.allow_password_change = False/' /root/.jupyter/jupyter_notebook_config.py && \
    sed -i '/^#.*c.NotebookApp.password_required /s/^#//' /root/.jupyter/jupyter_notebook_config.py && \
    sed -i '/^#.*c.NotebookApp.password ''/s/^#c.NotebookApp.password = \x27\x27/c.NotebookApp.password = u\x27'"$WEB_PASSWORD_HASH"'\x27/' /root/.jupyter/jupyter_notebook_config.py && \
    mkdir /notebooks

# Copy additional libs
COPY libs/hadoop-aws-2.7.7.jar /opt/spark/jars/
COPY libs/aws-java-sdk-1.7.4.jar /opt/spark/jars/
COPY libs/sqljdbc42.jar /opt/spark/jars
COPY pythonrc /root/.pythonrc
COPY kernel.json /root/.local/share/jupyter/kernels/spark/kernel.json
COPY start.sh /

EXPOSE	8888

WORKDIR	/notebooks

ENTRYPOINT ["/bin/bash", "/start.sh"]
