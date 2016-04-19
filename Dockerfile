FROM scratch
ADD main /
EXPOSE 80:9090
CMD ["/main"]
