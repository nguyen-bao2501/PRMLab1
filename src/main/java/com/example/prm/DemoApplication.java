package com.example.prm;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;

/*
 * Domain classes were created in top-level packages (controller, service,
 * repository, entity), outside com.example.prm. Explicit scanning is required;
 * otherwise the application starts without any API, service, entity or JPA
 * repository being registered.
 */
@SpringBootApplication(scanBasePackages = {"com.example.prm", "config", "controller", "security", "service", "exception"})
@EntityScan(basePackages = "entity")
@EnableJpaRepositories(basePackages = "repository")
@EnableScheduling
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

}
