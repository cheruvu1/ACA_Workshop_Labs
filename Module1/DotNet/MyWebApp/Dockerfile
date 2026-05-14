# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app

# Copy csproj and restore dependencies (layer caching)
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Stage 2: Build the runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build-env /app/out .

# Standard port for .NET 8+ is 8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "MyWebApp.dll"]

