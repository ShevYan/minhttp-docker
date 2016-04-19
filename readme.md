# build minhttp server with docker

## clean old image

```
rm -rf ./main
docker rmi -f minhttp
```

## build go project
```
go build main.go
GO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .
```

## build docker image
```
docker build --no-cache -t minhttp .
```


## run image
```
docker run -p 80:9090 --rm minhttp
```

## access web
```
curl <ip>
```
