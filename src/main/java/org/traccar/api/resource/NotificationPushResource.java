package org.traccar.api.resource;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import org.traccar.api.BaseResource;
import org.traccar.model.Device;
import org.traccar.model.Event;
import org.traccar.model.User;
import org.traccar.reports.model.ReportResponse;
import org.traccar.session.cache.CacheManager;
import org.traccar.storage.StorageException;
import org.traccar.storage.query.Columns;
import org.traccar.storage.query.Condition;
import org.traccar.storage.query.Order;
import org.traccar.storage.query.Request;


import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

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
                new Columns.Include("id"),
                new Condition.Permission(User.class, getUserId(), Device.class)));

        if (devices.isEmpty()) {
            return new ReportResponse<>(Collections.emptyList(), 0, limit, (long) offset);
        }

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
        Map<Long, String> deviceNames = new HashMap<>();
        for (Event event : items) {
            long deviceId = event.getDeviceId();
            if (!deviceNames.containsKey(deviceId)) {
                Device device = cacheManager.getObject(Device.class, deviceId);
                if (device == null) {
                    device = storage.getObject(Device.class, new Request(
                            new Columns.Include("id", "name"), new Condition.Equals("id", deviceId)));
                }
                if (device != null) {
                    deviceNames.put(deviceId, device.getName());
                }
            }
            event.setDeviceName(deviceNames.get(deviceId));
        }
        long totalItems = storage.getCount(Event.class, new Request(condition));

        return new ReportResponse<>(items, totalItems, limit, (long) offset);
    }

}
