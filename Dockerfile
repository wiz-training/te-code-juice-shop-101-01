FROM bkimminich/juice-shop:v17.1.1
# Deliberate: the lab's finding. Patch replaces this with a non-root user.
USER node
# Per-slot instruction: Docker Correlation keys on identical instructions, so without it one image
# matches every pool repo's Dockerfile.
ENV LAB_SLOT=01
EXPOSE 3000
