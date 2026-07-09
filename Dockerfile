FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
RUN addgroup --group simulator --gid 2000 && adduser --uid 1000 --gid 2000 --disabled-password --gecos '' "simulator"
RUN mkdir /workspace
RUN chown -R simulator:simulator /app
RUN chown -R simulator:simulator /workspace
USER simulator:simulator
COPY * /app/
COPY --from=mcr.microsoft.com/dotnet/aspnet:7.0 /etc/ssl/openssl.cnf /etc/ssl/openssl.cnf
EXPOSE 17070-17077
ENTRYPOINT ["/app/Tricentis.Simulator.Agent", "/workspace", "-p 17070", "--no-ui"]