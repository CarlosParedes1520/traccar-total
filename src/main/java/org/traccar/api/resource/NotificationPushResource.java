package org.traccar.api.resource;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.traccar.api.BaseResource;
import org.traccar.model.Device;
import org.traccar.model.Event;
import org.traccar.model.User;
import org.traccar.reports.model.ReportResponse;
import org.traccar.model.ObjectOperation;
import org.traccar.session.cache.CacheManager;
import org.traccar.storage.StorageException;
import org.traccar.storage.query.Columns;
import org.traccar.storage.query.Condition;
import org.traccar.storage.query.Order;
import org.traccar.storage.query.Request;

import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Path("notifications/push")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class NotificationPushResource extends BaseResource {

    @Inject
    private CacheManager cacheManager;

    @GET
    public ReportResponse<Event> get(
            @QueryParam("limit") int limit,
            @QueryParam("offset") int offset) throws StorageException {

        if (limit == 0) {
            limit = 10;
        }

        Condition typeCondition = new Condition.Equals("type", Event.TYPE_DEVICE_ONLINE);
        typeCondition = new Condition.Or(typeCondition, new Condition.Equals("type", Event.TYPE_DEVICE_OFFLINE));
        typeCondition = new Condition.Or(typeCondition, new Condition.Equals("type", Event.TYPE_GEOFENCE_ENTER));
        typeCondition = new Condition.Or(typeCondition, new Condition.Equals("type", Event.TYPE_GEOFENCE_EXIT));
        typeCondition = new Condition.Or(typeCondition, new Condition.Equals("type", Event.TYPE_DEVICE_OVERSPEED));
        typeCondition = new Condition.Or(typeCondition, new Condition.Equals("type", Event.TYPE_ALARM));
        typeCondition = new Condition.Or(typeCondition, new Condition.Equals("type", Event.TYPE_IGNITION_ON));
        typeCondition = new Condition.Or(typeCondition, new Condition.Equals("type", Event.TYPE_IGNITION_OFF));

        var devices = storage.getObjects(Device.class, new Request(
                new Columns.Include("id", "name"),
                new Condition.Permission(User.class, getUserId(), Device.class)));

        if (devices.isEmpty()) {
            return new ReportResponse<>(Collections.emptyList(), 0, limit, (long) offset);
        }

        // Build device condition more efficiently
        Condition deviceCondition = null;
        for (Device device : devices) {
            Condition equals = new Condition.Equals("deviceId", device.getId());
            if (deviceCondition == null) {
                deviceCondition = equals;
            } else {
                deviceCondition = new Condition.Or(deviceCondition, equals);
            }
        }

        Condition condition = new Condition.And(deviceCondition, typeCondition);
        Order order = new Order("id", true, limit, offset);
        Request request = new Request(new Columns.All(), condition, order);

        Collection<Event> items = storage.getObjects(Event.class, request);
        
        // Fix N+1 query problem: Pre-fetch all device names in one query
        Map<Long, String> deviceNames = new HashMap<>();
        Set<Long> deviceIds = items.stream()
                .map(Event::getDeviceId)
                .collect(Collectors.toSet());
        
        // Use already fetched devices map for quick lookup
        Map<Long, Device> deviceMap = devices.stream()
                .collect(Collectors.toMap(Device::getId, device -> device));
        
        // For any missing devices, fetch them in batch (should be rare)
        Set<Long> missingDeviceIds = new HashSet<>(deviceIds);
        missingDeviceIds.removeAll(deviceMap.keySet());
        
        if (!missingDeviceIds.isEmpty()) {
            // Fetch missing devices in one query
            for (Long deviceId : missingDeviceIds) {
                Device device = cacheManager.getObject(Device.class, deviceId);
                if (device == null) {
                    device = storage.getObject(Device.class, new Request(
                            new Columns.Include("id", "name"), new Condition.Equals("id", deviceId)));
                }
                if (device != null) {
                    deviceMap.put(deviceId, device);
                }
            }
        }
        
        // Build device names map from device map
        for (Long deviceId : deviceIds) {
            Device device = deviceMap.get(deviceId);
            if (device != null) {
                deviceNames.put(deviceId, device.getName());
            }
        }
        
        // Set device names on events
        for (Event event : items) {
            event.setDeviceName(deviceNames.get(event.getDeviceId()));
        }
        
        long totalItems = storage.getCount(Event.class, new Request(condition));

        return new ReportResponse<>(items, totalItems, limit, (long) offset);
    }

    @POST
    public Response registerToken(PushTokenRequest request) throws StorageException, Exception {
        if (request == null || request.token == null || request.token.trim().isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("error", "Token is required"))
                    .build();
        }

        long userId = getUserId();
        if (userId <= 0) {
            return Response.status(Response.Status.UNAUTHORIZED).build();
        }

        String token = request.token.trim();
        String type = request.type != null ? request.type.toLowerCase() : "fcm";

        if (!"fcm".equals(type)) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("error", "Unsupported token type: " + type))
                    .build();
        }

        // Load ONLY the columns we will update (id, attributes, fcmtoken).
        // This avoids ever passing a User that has null hashedPassword/salt into
        // any update path, preventing accidental overwrite of credentials.
        User userToUpdate = storage.getObject(User.class, new Request(
                new Columns.Include("id", "attributes", "fcmtoken"),
                new Condition.Equals("id", userId)));
        if (userToUpdate == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }

        // Merge token into attributes (notificationTokens) and fcmtoken
        if (userToUpdate.hasAttribute("notificationTokens")) {
            String existing = userToUpdate.getString("notificationTokens");
            List<String> tokens = new java.util.ArrayList<>(
                    java.util.Arrays.asList(existing.split("[, ]")));
            if (!tokens.contains(token)) {
                tokens.add(token);
                userToUpdate.set("notificationTokens", String.join(",", tokens));
            }
        } else {
            userToUpdate.set("notificationTokens", token);
        }
        if (userToUpdate.getFcmtoken() == null || userToUpdate.getFcmtoken().isEmpty()) {
            userToUpdate.setFcmtoken(token);
        }

        // Update ONLY attributes and fcmtoken. Never touch hashedPassword/salt.
        storage.updateObject(userToUpdate, new Request(
                new Columns.Include("attributes", "fcmtoken"),
                new Condition.Equals("id", userId)));

        cacheManager.invalidateObject(true, User.class, userId, ObjectOperation.UPDATE);

        return Response.noContent().build();
    }

    // Inner class for request body
    public static class PushTokenRequest {
        public String token;
        public String type;
    }

}
