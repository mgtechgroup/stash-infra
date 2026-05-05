package com.openliberty.health;

import org.eclipse.microprofile.health.Health;
import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;

import javax.enterprise.context.ApplicationScoped;

/**
 * Health Check Endpoint for Open Liberty
 * Accessible at http://localhost:9080/health
 */
@Health
@ApplicationScoped
public class LivenessCheck implements HealthCheck {

    @Override
    public HealthCheckResponse call() {
        try {
            // Check basic connectivity
            return HealthCheckResponse.up("OpenLibertyLiveness")
                    .withData("status", "UP")
                    .withData("timestamp", System.currentTimeMillis())
                    .build();
        } catch (Exception e) {
            return HealthCheckResponse.down("OpenLibertyLiveness")
                    .withData("error", e.getMessage())
                    .build();
        }
    }
}
