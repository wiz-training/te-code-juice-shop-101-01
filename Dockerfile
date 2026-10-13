FROM bkimminich/juice-shop:v17.1.1
# Deliberate: the lab's finding. Patch replaces this with a non-root user.
USER root
EXPOSE 3000
