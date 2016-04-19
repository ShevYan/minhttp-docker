rm -rf ./main
docker rmi -f minhttp
go build main.go
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .
docker build --no-cache -t minhttp .
