# Argo CD Timoni CMP

> A [Custom Management Plugin][cmp] for deploying [Timoni] modules

## Usage

This CMP ships as a container with the Timoni binary available and the CMP configuration already baked into the image.
In order to use it, you must add it as a sidecar to the `argocd-repo-server` pod:

```yaml
  - image: ghcr.io/jmgilman/argo-cmp-timoni:0.1.0
    imagePullPolicy: IfNotPresent
    name: argo-cmp-timoni
    resources: {}
    securityContext:
      runAsNonRoot: true
      runAsUser: 999
    volumeMounts:
    - mountPath: /var/run/argocd
      name: var-files
    - mountPath: /home/argocd/cmp-server/plugins
      name: plugins
    - mountPath: /tmp
      name: cmp-tmp
```

Then ensure that the additional volume is also added:

```yaml
  - emptyDir: {}
    name: cmp-tmp
```

## How it Works

The CMP only works with [Timoni bundle files][bundle].
It assumes that a single `bundle.cue` file exists at the root of the project directory.
It will automatically generate YAML for Argo CD to use by running `timoni bundle build -f ./bundle.cue`.

## Authentication

### AWS

If your bundle requires access to OCI images hosted behind a private ECR repository, it's possible to configure the CMP container
to enable access for fetching images.
First, you must create an [IRSA] role for the `argocd-repo-server` service account:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::111111111111:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/AAAAAAAAAABBBBBBBBBBBCCCCCCCCCCCC"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/AAAAAAAAAABBBBBBBBBBBCCCCCCCCCCCC:sub": "system:serviceaccount:argocd:argocd-repo-server",
                    "oidc.eks.us-east-1.amazonaws.com/id/AAAAAAAAAABBBBBBBBBBBCCCCCCCCCCCC:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
```

Then you should attach a policy to this role which allows fetching ECR images:

```json
{
    "Statement": [
        {
            "Action": [
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetAuthorizationToken",
                "ecr:GetDownloadUrlForLayer"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
```

Finally, you must patch the `argocd-repo-server` service account with a new annotation:

```
annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::111111111111:role/irsa-role
```

During the initialization phase, the CMP will automatically configure [AWS ECR Credential Helper][ecr-helper] using information from
the environment.
Specifically, it gets the current region from `AWS_REGION` and the AWS account ID from parsing `AWS_ROLE_ARN`.
It will use these two values to configure a helper like so:

```json
{
    "credHelpers": {
        "111111111111.dkr.ecr.us-east-1.amazonaws.com": "ecr-login"
    }
}
```

If for some reason your images live in a different region and/or account, you can override this behavior when configuring the
plugin:

```
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    plugin:
      env:
        - name: REGION
          value: us-west-2
        - name: ACCOUNT_ID
          value: 222222222222
```

With this in place, you may now reference private ECR images in your `bundle.cue` files:

```cue
bundle: {
        apiVersion: "v1alpha1"
        name:       "podinfo"
        instances: {
                app: {
                        module: {
                                url:     "oci://111111111111.dkr.ecr.us-east-1.amazonaws.com/app"
                                version: "0.0.1"
                        }
                        namespace: "default"
                        values: {
                                image: tag: "1.0.0"
                        }
                }
        }
}
```

[bundle]: https://timoni.sh/bundle/
[cmp]: https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/
[ecr-helper]: https://github.com/awslabs/amazon-ecr-credential-helper
[irsa]: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
[Timoni]: https://timoni.sh