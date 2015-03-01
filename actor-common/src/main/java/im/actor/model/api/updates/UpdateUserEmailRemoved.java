package im.actor.model.api.updates;
/*
 *  Generated by the Actor API Scheme generator.  DO NOT EDIT!
 */

import im.actor.model.droidkit.bser.Bser;
import im.actor.model.droidkit.bser.BserObject;
import im.actor.model.droidkit.bser.BserValues;
import im.actor.model.droidkit.bser.BserWriter;
import static im.actor.model.droidkit.bser.Utils.*;
import java.io.IOException;
import im.actor.model.network.parser.*;
import java.util.List;
import java.util.ArrayList;
import im.actor.model.api.*;

public class UpdateUserEmailRemoved extends Update {

    public static final int HEADER = 0x61;
    public static UpdateUserEmailRemoved fromBytes(byte[] data) throws IOException {
        return Bser.parse(new UpdateUserEmailRemoved(), data);
    }

    private int uid;
    private int emailId;

    public UpdateUserEmailRemoved(int uid, int emailId) {
        this.uid = uid;
        this.emailId = emailId;
    }

    public UpdateUserEmailRemoved() {

    }

    public int getUid() {
        return this.uid;
    }

    public int getEmailId() {
        return this.emailId;
    }

    @Override
    public void parse(BserValues values) throws IOException {
        this.uid = values.getInt(1);
        this.emailId = values.getInt(2);
    }

    @Override
    public void serialize(BserWriter writer) throws IOException {
        writer.writeInt(1, this.uid);
        writer.writeInt(2, this.emailId);
    }

    @Override
    public String toString() {
        String res = "update UserEmailRemoved{";
        res += "uid=" + this.uid;
        res += ", emailId=" + this.emailId;
        res += "}";
        return res;
    }

    @Override
    public int getHeaderKey() {
        return HEADER;
    }
}
