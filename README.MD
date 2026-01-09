

gcloud iam workload-identity-pools create github-pool \
--project=topcrops \
--location=global \
--display-name="GitHub Actions Pool"


gcloud iam workload-identity-pools providers create-oidc github-provider \
--project=topcrops \
--location=global \
--workload-identity-pool=github-pool \
--display-name="GitHub OIDC Provider" \
--issuer-uri="https://token.actions.githubusercontent.com" \
--attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository"



