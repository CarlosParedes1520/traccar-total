package org.traccar.api.resource;

import jakarta.annotation.security.PermitAll;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.traccar.api.BaseResource;
import org.traccar.model.User;
import org.traccar.storage.StorageException;
import org.traccar.storage.query.Columns;
import org.traccar.storage.query.Condition;
import org.traccar.storage.query.Request;

import java.util.Date;
import java.util.Map;

@Path("/")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PasswordKeyResource extends BaseResource {

    @Path("generatePasswordKey")
    @PermitAll
    @GET
    public Response generatePasswordKey(@QueryParam("email") String email) throws StorageException {
        User user = storage.getObject(User.class, new Request(
                new Columns.All(), new Condition.Equals("email", email)));

        if (user == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }

        String key = java.util.concurrent.ThreadLocalRandom.current().ints(12, 0, 62)
                .mapToObj(i -> "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".substring(i, i + 1))
                .collect(java.util.stream.Collectors.joining());
        Date expiresDate = new Date(System.currentTimeMillis() + 5 * 60 * 1000); // 5 minutes

        user.setTemporarykey(key);
        user.setTemporarykeyexpiration(expiresDate);

        storage.updateObject(user, new Request(
                new Columns.Include("temporarykey", "temporarykeyexpiration"),
                new Condition.Equals("id", user.getId())));

        return Response.ok(Map.of(
                "temporaryKey", key,
                "email", email,
                "expiresAt", java.time.OffsetDateTime.now(java.time.ZoneOffset.UTC)
                        .plusMinutes(5)
                        .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"))
        )).build();
    }

    public static class ChangePasswordDetails {
        private String temporaryKey;
        private String password;
        private String confirmPassword;

        public String getTemporaryKey() {
            return temporaryKey;
        }

        public void setTemporaryKey(String temporaryKey) {
            this.temporaryKey = temporaryKey;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }

        public String getConfirmPassword() {
            return confirmPassword;
        }

        public void setConfirmPassword(String confirmPassword) {
            this.confirmPassword = confirmPassword;
        }
    }

    @Path("changePassword")
    @PermitAll
    @POST
    public Response changePassword(ChangePasswordDetails details) throws StorageException {

        if (details.getPassword() == null || !details.getPassword().equals(details.getConfirmPassword())) {
            return Response.status(Response.Status.BAD_REQUEST).entity("Passwords do not match").build();
        }

        User user = storage.getObject(User.class, new Request(
                new Columns.All(), new Condition.Equals("temporarykey", details.getTemporaryKey())));

        if (user == null) {
            return Response.status(Response.Status.BAD_REQUEST).entity("Invalid key").build();
        }

        if (user.getTemporarykeyexpiration().before(new Date())) {
            return Response.status(Response.Status.BAD_REQUEST).entity("Key expired").build();
        }

        user.setPassword(details.getPassword());
        user.setTemporarykey(null);
        user.setTemporarykeyexpiration(null);

        storage.updateObject(user, new Request(
                new Columns.Include("hashedPassword", "salt", "temporarykey", "temporarykeyexpiration"),
                new Condition.Equals("id", user.getId())));

        return Response.ok("Password changed successfully").build();
    }
}
