package com.openliberty.api;

import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

/**
 * REST API Endpoint for Open Liberty
 * Base path: http://localhost:9080/api
 */
@Path("/api")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ApiResource {

    @GET
    @Path("/status")
    public Response getStatus() {
        return Response.ok()
                .entity(new StatusResponse("UP", System.currentTimeMillis()))
                .build();
    }

    @GET
    @Path("/info")
    public Response getInfo() {
        return Response.ok()
                .entity(new InfoResponse(
                        System.getProperty("java.version"),
                        System.getProperty("os.name"),
                        System.getProperty("os.arch")
                ))
                .build();
    }

    @POST
    @Path("/echo")
    public Response echo(String message) {
        return Response.ok()
                .entity(new EchoResponse(message))
                .build();
    }

    // Response DTOs
    static class StatusResponse {
        public String status;
        public long timestamp;

        public StatusResponse(String status, long timestamp) {
            this.status = status;
            this.timestamp = timestamp;
        }
    }

    static class InfoResponse {
        public String javaVersion;
        public String osName;
        public String osArch;

        public InfoResponse(String javaVersion, String osName, String osArch) {
            this.javaVersion = javaVersion;
            this.osName = osName;
            this.osArch = osArch;
        }
    }

    static class EchoResponse {
        public String message;
        public long timestamp;

        public EchoResponse(String message) {
            this.message = message;
            this.timestamp = System.currentTimeMillis();
        }
    }
}
