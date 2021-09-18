#kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

#eksctl 설치
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C ./
mv eksctl /home/ubuntu/environment/minseoklee/sw/eksctl/eksctl

#본인의 AWS 자격증명 키 셋팅
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

# VPC 생성
aws cloudformation create-stack --stack-name aws-ttt-3 --template-body file:///home/ubuntu/environment/minseoklee/aws-ttt-3-config/aws-ttt-3.yaml --region ap-northeast-2

#DB는 아직 명령어로 생성되도록 만들지 못했음. AWS Management Console에서 UI를 통해 생성할것

#DB 모델 변경
#DB는 다 VPC에서 접속하지 못하게 되어있으므로 임시적으로 생성한 VPC 망 내에 Cloud9 생성해서 파일 복사 후 아래 명령을 실행할 것
#복사파일 대상 : /home/ubuntu/environment/minseoklee/aws-ttt-3-config/create-db-account.sql
#복사 디렉토리 : sudo mkdir -p /home/ubuntu/environment/minseoklee/aws-ttt-3-config/
#vi 에디터 : sudo vi /home/ubuntu/environment/minseoklee/aws-ttt-3-config/create-db-account.sql
mysql -u root -p -h aws-ttt-3-db-instance-1.cgt4zl5rdd9h.ap-northeast-2.rds.amazonaws.com < /home/ubuntu/environment/minseoklee/aaws-ttt-3-config/create-db-account.sql

#eks 클러스터 생성(노드그룹도 같이 생성됨)
/home/ubuntu/environment/minseoklee/sw/eksctl/eksctl create cluster -f /home/ubuntu/environment/minseoklee/aws-ttt-3-config/aws-ttt-3-cluster.yaml

# AWS ECR Docker Registry login
aws ecr get-login-password --region ap-northeast-2 | docker login -u AWS --password-stdin 734268896595.dkr.ecr.ap-northeast-2.amazonaws.com

# example-order gradle build
cd /home/ubuntu/environment/minseoklee/example-order && ./gradlew build --exclude-task=test -Dorg.gradle.java.home=/home/ubuntu/environment/minseoklee/sw/jdk-16.0.2

# 테스트 차원에서 example-order 실행하기(사전에 docker-compose 설치 필요, DB 기동)
docker-compose -f /home/ubuntu/environment/minseoklee/example-order/docker-compose/docker-compose.yml up

# 테스트 차원에서 example-order 실행하기(DB 계정 만들어주세요.. database명 : order, 계정명 : order-svc, 비밀번호 : order-pass 생성 후 스크립트 실행, 스크립트 위치 : /home/ubuntu/environment/minseoklee/example-order/src/main/resources/db/migration/V1__init_ddl.sql)
# DB 접속하기 - docker exec -it $(도커명) /bin/bash  (도커명은 docker ps -a로 확인 가능합니다.)

# 테스트 서비스 실행
JAVA_HOME=/home/ubuntu/environment/minseoklee/sw/jdk-16.0.2 && $JAVA_HOME/bin/java -jar /home/ubuntu/environment/minseoklee/example-order/build/libs/order-0.0.1-SNAPSHOT.jar

# example-order Docker 이미지 빌드
docker build -t 734268896595.dkr.ecr.ap-northeast-2.amazonaws.com/example-order:latest /home/ubuntu/environment/minseoklee/example-order

# example-order ECR Docker Registry로 Push
docker push 734268896595.dkr.ecr.ap-northeast-2.amazonaws.com/example-order:latest

# example-gift gradle build(application.yml 파일에 SQS용 IAM의 토큰 수정해서 빌드해주세요..)
cd /home/ubuntu/environment/minseoklee/example-gift && ./gradlew build --exclude-task=test -Dorg.gradle.java.home=/home/ubuntu/environment/minseoklee/sw/jdk-16.0.2

# 테스트 차원에서 example-gift 실행하기(사전에 docker-compose 설치 필요)
docker-compose -f /home/ubuntu/environment/minseoklee/example-gift/docker-compose/docker-compose.yml up

# 테스트 차원에서 example-gift 실행하기(DB 계정 만들어주세요.. database명 : gift, 계정명 : gift-svc, 비밀번호 : gift-pass 생성 후 스크립트 실행, 스크립트 위치 : /home/ubuntu/environment/minseoklee/example-gift/src/main/resources/db/migration/V1__init_ddl.sql)
# DB 접속하기 - docker exec -it $(도커명) /bin/bash  (도커명은 docker ps -a로 확인 가능합니다.)

# 테스트 서비스 실행(application.yml 파일에 SQS용 IAM의 토큰 수정해서 기동해주세요..)
JAVA_HOME=/home/ubuntu/environment/minseoklee/sw/jdk-16.0.2 && $JAVA_HOME/bin/java -jar /home/ubuntu/environment/minseoklee/example-gift/build/libs/gift-0.0.1-SNAPSHOT.jar

# example-gift Docker 이미지 빌드
docker build -t 734268896595.dkr.ecr.ap-northeast-2.amazonaws.com/example-gift:latest /home/ubuntu/environment/minseoklee/example-gift

# example-gift ECR Docker Registry로 Push
docker push 734268896595.dkr.ecr.ap-northeast-2.amazonaws.com/example-gift:latest

#kubectl 접속 설정
aws eks update-kubeconfig --name aws-ttt-3-cluster

# k8s namespace 생성
kubectl apply -f /home/ubuntu/environment/minseoklee/aws-ttt-3-config/example-order-namespace.yaml

# k8s deployment 생성
kubectl apply -f /home/ubuntu/environment/minseoklee/aws-ttt-3-config/example-order-deployment.yaml

# k8s 서비스 생성
kubectl apply -f /home/ubuntu/environment/minseoklee/aws-ttt-3-config/example-order-service.yaml

# 기동 점검(추후 작성)
curl -X POST http://~~~/~~~