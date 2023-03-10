#Use Official image of JDK Bionic
FROM adoptopenjdk:8u232-b09-jdk-hotspot-bionic

LABEL maintainer=javier.godino@acqua.net.ar

# ===============================================================================
# Define environment variables.
# ===============================================================================
#
# -4.4.0-20221111
#
ENV BASE_INSTALL_DIR=/opt \
   MULE_HOME=/opt/mule-enterprise-standalone-4.4.0-20221111 \
   MULE_REPOSITORY=http://157.245.236.175:8081/artifactory/libs-release \
   MULE_USER=mule \
   MULE_MD5SUM='419553149ed6c42c30254b1a1fa26f02' \
   MULE_FILE_STANDALONE_NAME=mule-enterprise-standalone \
   MULE_FILE_DISTRIBUTION_NAME=mule-ee-distribution-standalone \
   MULE_VERSION=4.4.0 \
   MULE_VERSION_COMP=4.4.0-20221111 \
   TZ=Europe/Madrid \
   MULE_LICENSE=license.lic

# ===============================================================================
# COPY Components
# ===============================================================================
COPY ./mule ${BASE_INSTALL_DIR}/${MULE_FILE_STANDALONE_NAME}-${MULE_VERSION_COMP}/
 
# ===============================================================================
# Create Mule group and user
# =============================================================================== 
RUN groupadd -r ${MULE_USER} && useradd -r -m -c "Mule runtime user" ${MULE_USER} -g ${MULE_USER} && \
    chown -R ${MULE_USER}:${MULE_USER} ${BASE_INSTALL_DIR}/${MULE_FILE_STANDALONE_NAME}-${MULE_VERSION_COMP} && \
    ln -s ${BASE_INSTALL_DIR}/${MULE_FILE_STANDALONE_NAME}-${MULE_VERSION_COMP} ${MULE_HOME} 
  
# ===============================================================================
# Ponemos la zona horaria correctamente
# ===============================================================================
# 
RUN echo ${TZ} > /etc/timezone

# ===============================================================================
# Default user
# ===============================================================================
# 
USER ${MULE_USER}

# ===============================================================================
# Download mule-standalone
# ===============================================================================
RUN set -ex && \
    cd ~ && \ 
	curl -O ${MULE_REPOSITORY}/com/mule/${MULE_FILE_DISTRIBUTION_NAME}/${MULE_VERSION}/${MULE_FILE_DISTRIBUTION_NAME}-${MULE_VERSION}.tar.gz && \
	echo "${MULE_MD5SUM}  ${MULE_FILE_DISTRIBUTION_NAME}-${MULE_VERSION}.tar.gz" | md5sum -c

RUN echo "**********************************************************************"
RUN ls -R ~
RUN echo "**********************************************************************"
RUN ls -R ${BASE_INSTALL_DIR}
RUN echo "**********************************************************************"
# ===============================================================================
# Install mule-standalone
# ===============================================================================
RUN set -ex && \
    cd ~ && \ 
	tar -xvzf ${MULE_FILE_DISTRIBUTION_NAME}-${MULE_VERSION}.tar.gz -C ${BASE_INSTALL_DIR} && \
    mv ${MULE_HOME}/conf/log4j2.xml ${MULE_HOME}/conf/log4j2.xml.default && \
    mv ${MULE_HOME}/conf/mule-container-log4j2.xml ${MULE_HOME}/conf/log4j2.xml && \
    rm ${MULE_FILE_DISTRIBUTION_NAME}-${MULE_VERSION}.tar.gz

# ===============================================================================
# Copy and install license
# ===============================================================================

CMD echo "------ Copy and install license --------"
COPY $MULE_LICENSE $MULE_HOME/conf/
RUN $MULE_HOME/bin/mule -installLicense $MULE_HOME/conf/$MULE_LICENSE
RUN $MULE_HOME/bin/mule -verifyLicense

# ===============================================================================
#Copy and deploy mule application in runtime
# ===============================================================================

#CMD echo "------ Deploying mule application in runtime ! --------"
#COPY test-muleapp.jar $MULE_HOME/apps/
#RUN ls -ltr $MULE_HOME/apps/

# ===============================================================================
# Define mount points.
# ===============================================================================

VOLUME ["${MULE_HOME}/logs", "${MULE_HOME}/conf", "${MULE_HOME}/apps", "${MULE_HOME}/domains"]

# ===============================================================================
# Define working directory.
# ===============================================================================
WORKDIR ${MULE_HOME}

# ===============================================================================
# HTTP Service Port
# ===============================================================================
# -------------------------------------------------------------
# Expose the necessary port ranges as required by the Mule Apps
# -------------------------------------------------------------
EXPOSE 8081-8091
EXPOSE 9000
EXPOSE 9082
# ----------------------------------------------------
# Configure external access:
#       HTTPS Port for Anypoint Platform communication
# ----------------------------------------------------
EXPOSE  443
# ----------------------------------------------------
# Mule remote debugger
# ----------------------------------------------------
EXPOSE 5000
# ----------------------------------------------------
# Mule JMX port (must match Mule config file)
# ----------------------------------------------------
EXPOSE 1098
# ----------------------------------------------------
# Mule MMC agent port
# ----------------------------------------------------
EXPOSE 7777
# ----------------------------------------------------
# AMC agent port
# ----------------------------------------------------
EXPOSE 9997
# ----------------------------------------------------
# Mule Cluster ports
# ----------------------------------------------------
EXPOSE 5701
EXPOSE 54327

# ===============================================================================
# Start Mule runtime
# ===============================================================================
WORKDIR ${MULE_HOME}
ENTRYPOINT ["./bin/mule-container"]
CMD [""]
#CMD ["/opt/mule-enterprise-standalone-4.4.0-20221111/bin/mule", "-M-Dmule.agent.enabled=false"]