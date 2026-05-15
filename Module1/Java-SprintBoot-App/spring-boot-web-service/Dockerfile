FROM eclipse-temurin:21-jre

# Create the user and group first
RUN addgroup --system spring && adduser --system --ingroup spring spring

WORKDIR /app
COPY target/*.jar app.jar

# Now it's safe to switch to it
USER spring:spring

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

 


 