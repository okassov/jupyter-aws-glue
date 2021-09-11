# AWS Glue dev endpoint with Jupyter and Spark (Docker + EC2)

## Build

```console
$ docker build -t okassov/aws-glue:ec2 .
```

## Usage

```console
$ docker run -p8888:8888 --restart=always -d okassov/aws-glue:ec2 jupyter
```

Spark shell

```console
$ docker run -ti -rm okassov/aws-glue-dev-ec2 pyspark
```

> Note: If you run on EC2 Instance use instance profile with permission for aws-glue

> Note: If you run localy mount your ~/.aws folder with AccessKey and SecretKey to /root/.aws

> Note: For using Jupyter generate password hash and use WEB_PASSWORD_HASH environment variable

## Password Generating for Jupyter

1. Run jupyter docker
2. Create notebook and paste

```python
from IPython.lib import passwd
password = passwd("your_password")
```

3. Run code and get sha1 hash

4. Use this hash in Dockerfile for local dev-endpoint and build new image

