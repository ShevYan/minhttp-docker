# 通过docker构建最小的http服务

通常我们在使用docker的时候，都会使用ubuntu, centos, debian等基础镜像，但是这些基础镜像基本都在100M左右，是非常大的。那么我们如何通过docker快速构建一个最小的http服务呢？我们需要借助Golang和一些特殊处理来实现。

## 安装Docker 1.10
Docker目前可以通过国内的安装源进行安装，其中ghostcloud.cn是一家更新比较快的国内源。注册以后，选择接入主机，然后就能安装最新的Docker 1.10版本。

## Golang程序
```
package main

import (
	"fmt"
	"net/http"
	"strings"
	"log"
)

func sayhelloName(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	fmt.Println(r.Form)
	fmt.Println("path", r.URL.Path)
	fmt.Println("scheme", r.URL.Scheme)
	fmt.Println(r.Form["url_long"])
	for k, v := range r.Form {
		fmt.Println("key:", k)
		fmt.Println("val:", strings.Join(v, ""))
	}
	fmt.Fprintf(w, "Hello ghostcloud!")
}

func main() {
	http.HandleFunc("/", sayhelloName)
	err := http.ListenAndServe(":9090", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
```
上面的程序是一个最小化的go http程序，运行后会监听在9090端口上。

## 编译Go程序
默认我们可以通过：
```
go build main.go
```
来进行编译，但是这种编译是非静态模式，我们通过ldd命令可以查看到其依赖的库：
```
pzghost@pzghost:~/go/src/minhttp-docker$ go build main.go
pzghost@pzghost:~/go/src/minhttp-docker$ ldd main
	linux-vdso.so.1 =>  (0x00007ffd9aedd000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f08a9d56000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f08a9991000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f08a9f74000)
```
这种方式打包进容器运行是会报错的：
```
pzghost@pzghost:~/go/src/minhttp-docker$ docker run -p 80:9090 --rm minhttp
no such file or directory
docker: Error response from daemon: Container command not found or does not exist..
```

因此，我们需要进行静态编译：
```
pzghost@pzghost:~/go/src/minhttp-docker$ CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .
pzghost@pzghost:~/go/src/minhttp-docker$ ldd main
	not a dynamic executable
```

## Dockerfile
Dockerfile类似于Makefile，编译出image:
```
FROM scratch
ADD main /
EXPOSE 80:9090
CMD ["/main"]
```

这个Dockerfile的核心是基于scratch基础镜像，这个镜像是所有docker的基础镜像，因此是一个最小化的镜像。
## 编译镜像
```
docker build --no-cache -t minhttp .
pzghost@pzghost:~/go/src/minhttp-docker$ docker images | grep minhttp
minhttp                     latest              7bdfefdb9620        3 minutes ago       6.155 MB
```
这就是最后的镜像大小。

## 运行容器
```
pzghost@pzghost:~/go/src/minhttp-docker$ docker run -p 80:9090 --rm minhttp
Server started ...
```

## 访问网页
新开一个终端，访问http服务:
```
pzghost@pzghost:~$ curl localhost
Hello ghostcloud!
```

服务器端日志：
```
pzghost@pzghost:~/go/src/minhttp-docker$ docker run -p 80:9090 --rm minhttp
Server started ...
map[]
path /
scheme
[]
```

