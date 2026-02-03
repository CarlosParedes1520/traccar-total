package org.traccar.api.resource;

import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.traccar.api.BaseResource;
import org.traccar.model.Contact;
import org.traccar.storage.StorageException;
import org.traccar.storage.query.Columns;
import org.traccar.storage.query.Condition;
import org.traccar.storage.query.Request;

import java.util.Collection;
import java.util.LinkedList;

@Path("contacts")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ContactResource extends BaseResource {

    @GET
    public Collection<Contact> get() throws StorageException {
        var conditions = new LinkedList<Condition>();
        conditions.add(new Condition.Equals("userId", getUserId()));
        conditions.add(new Condition.Equals("status", true));
        return storage.getObjects(Contact.class, new Request(new Columns.All(), Condition.merge(conditions)));
    }

    @POST
    public Response add(Contact entity) throws Exception {
        entity.setUserId(getUserId());
        entity.setId(storage.addObject(entity, new Request(new Columns.Exclude("id"))));
        return Response.ok(entity).build();
    }

    @Path("{id}")
    @PUT
    public Response update(Contact entity) throws Exception {
        Contact existing = storage.getObject(Contact.class, new Request(
                new Columns.All(), new Condition.Equals("id", entity.getId())));
        if (existing == null || existing.getUserId() != getUserId()) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        entity.setUserId(getUserId());
        storage.updateObject(entity, new Request(
                new Columns.Exclude("id", "userId"),
                new Condition.Equals("id", entity.getId())));
        return Response.ok(entity).build();
    }

    @Path("{id}")
    @DELETE
    public Response remove(@PathParam("id") long id) throws Exception {
        Contact existing = storage.getObject(Contact.class, new Request(
                new Columns.All(), new Condition.Equals("id", id)));
        if (existing == null || existing.getUserId() != getUserId()) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        existing.setStatus(false);
        storage.updateObject(existing, new Request(
                new Columns.Include("status"),
                new Condition.Equals("id", id)));
        return Response.ok(existing).build();
    }
}
