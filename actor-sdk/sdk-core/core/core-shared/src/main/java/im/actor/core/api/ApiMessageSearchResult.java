package im.actor.core.api;
/*
 *  Generated by the Actor API Scheme generator.  DO NOT EDIT!
 */

import im.actor.runtime.bser.*;
import im.actor.runtime.collections.*;
import static im.actor.runtime.bser.Utils.*;
import im.actor.core.network.parser.*;
import org.jetbrains.annotations.Nullable;
import org.jetbrains.annotations.NotNull;
import com.google.j2objc.annotations.ObjectiveCName;
import java.io.IOException;
import java.util.List;
import java.util.ArrayList;

public class ApiMessageSearchResult extends BserObject {

    private ApiPeer peer;
    private long rid;
    private long date;
    private int senderId;
    private ApiMessage content;

    public ApiMessageSearchResult(@NotNull ApiPeer peer, long rid, long date, int senderId, @NotNull ApiMessage content) {
        this.peer = peer;
        this.rid = rid;
        this.date = date;
        this.senderId = senderId;
        this.content = content;
    }

    public ApiMessageSearchResult() {

    }

    @NotNull
    public ApiPeer getPeer() {
        return this.peer;
    }

    public long getRid() {
        return this.rid;
    }

    public long getDate() {
        return this.date;
    }

    public int getSenderId() {
        return this.senderId;
    }

    @NotNull
    public ApiMessage getContent() {
        return this.content;
    }

    @Override
    public void parse(BserValues values) throws IOException {
        this.peer = values.getObj(1, new ApiPeer());
        this.rid = values.getLong(2);
        this.date = values.getLong(3);
        this.senderId = values.getInt(4);
        this.content = ApiMessage.fromBytes(values.getBytes(5));
    }

    @Override
    public void serialize(BserWriter writer) throws IOException {
        if (this.peer == null) {
            throw new IOException();
        }
        writer.writeObject(1, this.peer);
        writer.writeLong(2, this.rid);
        writer.writeLong(3, this.date);
        writer.writeInt(4, this.senderId);
        if (this.content == null) {
            throw new IOException();
        }

        writer.writeBytes(5, this.content.buildContainer());
    }

    @Override
    public String toString() {
        String res = "struct MessageSearchResult{";
        res += "peer=" + this.peer;
        res += ", rid=" + this.rid;
        res += ", date=" + this.date;
        res += ", senderId=" + this.senderId;
        res += ", content=" + this.content;
        res += "}";
        return res;
    }

}
