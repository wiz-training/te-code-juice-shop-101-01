# juice-shop-101 — learner repository

Deployed for you by the lab. The running image is the upstream Juice Shop image re-tagged into the
sandbox registry with an `org.opencontainers.image.source` annotation that points at this Dockerfile,
so Wiz links the EC2's container back to this file. The `USER root` line trips the builtin IaC rule
"Last User Is 'root'"; the Patch action's PR replaces it.
