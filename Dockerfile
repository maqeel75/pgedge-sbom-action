FROM rockylinux:9

# Install dependencies
RUN dnf install -y vim jq tar gzip && dnf clean all

# Install syft
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Working directory
WORKDIR /opt

# Create SBOM output directory
RUN mkdir -p /opt/pg_sbom

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

